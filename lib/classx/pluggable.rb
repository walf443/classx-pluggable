require 'classx'
require 'ostruct'

module ClassX
  module Pluggable
    extend ClassX::Attributes
    extend ClassX::Role::Logger

    class PluginLoadError < ::Exception; end

    DEFAULT_PLUGIN_DIR = File.expand_path(File.join(File.dirname(__FILE__), File.basename(__FILE__).sub(/\.rb$/, ''), 'plugin'))

    has :__classx_pluggable_events_of,
        :lazy    => true,
        :no_cmd_option  => true,
        :default => proc {|mine| mine.events.inject({}) {|h,event| h[event] = []; h } }

    has :plugin_dir,
        :lazy   => true,
        :default => proc {
          [
            File.expand_path(File.join(File.dirname(__FILE__), File.basename(__FILE__).sub(/\.rb$/, ''), 'plugin')),
            DEFAULT_PLUGIN_DIR
          ].uniq
        }

    has :check_events,
      :default  => false,
      :optional => true,
      :desc     => "only add events that define before add_event."

    has :events,
      :lazy => true,
      :optional => true,
      :kind_of  => Array,
      :desc    => "hook point for #{self}'s instance",
      :default => proc { [] }

    def add_event name, plugin, meth
      name = name.to_s
      if self.check_events && !self.events.include?(name)
        raise "#{name.inspect} should be declared before call add_event. not in #{self.events.inspect}"
      else
        self.__classx_pluggable_events_of[name] ||= []
      end
      self.__classx_pluggable_events_of[name] << { :plugin => plugin, :method => meth }
    end

    def load_plugins plugins
      load_components("plugin", plugins)
    end

    def load_components type, components
      components.each do |component|
        load_component type, component
      end
    end

    def load_component type, hash
      component = OpenStruct.new(hash)
      mod = component_class_get(type, component.module)
      component.config ||= {}
      component.config[:context] = self
      instance = mod.new(component.config)
      instance.register
      logger.debug("ClassX::Pluggable: loaded #{type} #{component.module}, config=#{instance.inspect}")
    end

    def call_event name, *args
      name = name.to_s
      if events = self.__classx_pluggable_events_of[name]
        events.map do |event|
          event[:plugin].__send__(event[:method], *args)
        end
      else
        []
      end
    end

    # invoke hook BEFORE_xxxx and yield block and invoke hook AFTER_xxxx.
    def around_event name, *args, &block
      name = name.to_s
      around_name = "AROUND_#{name}"

      call_event("BEFORE_#{name}", *args)
      if events = self.__classx_pluggable_events_of[around_name]
        procs = []
        procs << block
        index = 0
        nested_proc = events.inject(block) {|bl, event| proc { event[:plugin].__send__(event[:method], *args, &bl ) } }
        nested_proc.call
      end
      call_event("AFTER_#{name}", *args)
    end

    private

    def after_init
      self.plugin_dir.each do |path|
        Dir.glob("#{path}/**/*.rb").each do |file|
          guess_autoload(file)
        end
      end
    end

    def guess_autoload file
      autoload path2module(path), path
    end

    def path2module path
      path
    end

    def module2path mod
      mod
    end

    def component_class_get type, name
      case name
      when ::Class
        return name
      else
        begin
          if name =~ /\A\+(.+)\z/
              mod_name = $1
              base = self.class.const_get(type.capitalize)
              base.const_get(mod_name)
          else
            name_spaces = name.split(/::/)
            result = ::Object
            name_spaces.each do |const|
              result = result.const_get(const)
            end
            return result
          end
        rescue NameError => e
          raise PluginLoadError, "module: #{name} is not found."
        end
      end
    end

    # It's useful for testing.
    class MockContext
      include ClassX
      include ClassX::Pluggable
    end
  end
end
