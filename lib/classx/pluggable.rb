require 'classx'
require 'ostruct'

module ClassX
  # in your context class.
  #
  #   require 'classx'
  #   require 'classx/pluggable'
  #   class YourApp
  #     include ClassX
  #     include ClassX::Pluggable
  #
  #     def run
  #       call_event("SETUP", {})
  #       # you app
  #       call_event("TEARDOWN", {})
  #     end
  #
  #   end
  #
  # in your plugin class
  #
  #   require 'classx'
  #   require 'classx/pluggable'
  #   class YourApp
  #     class Plugin
  #       include ClassX
  #       include ClassX::Pluggable::Plugin
  #
  #       class SomePlugin < Plugin
  #         def register
  #           add_event("SETUP", :on_setup)
  #         end
  #
  #         def on_setup param
  #           # param is Hash
  #           # hooked setup
  #         end
  #       end
  #     end
  #   end
  #
  module Pluggable
    extend ClassX::Attributes
    extend ClassX::Role::Logger

    class PluginLoadError < ::Exception; end

    has :__classx_pluggable_events_of,
        :lazy    => true,
        :no_cmd_option  => true,
        :default => proc {|mine| mine.events.inject({}) {|h,event| h[event] = []; h } }

    has :plugin_dir,
        :optional => true,
        :kind_of  => Array

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

    # register plugin and method to hook point.
    #
    def add_event name, plugin, meth
      name = name.to_s
      if self.check_events && !self.events.include?(name)
        raise "#{name.inspect} should be declared before call add_event. not in #{self.events.inspect}"
      else
        self.__classx_pluggable_events_of[name] ||= []
      end
      self.__classx_pluggable_events_of[name] << { :plugin => plugin, :method => meth }
    end

    # load plugins.
    #
    #   app.load_plugins([
    #     { :module => "YourApp::Plugin::Foo", :confiig => { :some_config => "foo"} },
    #     { :module => "+Bar", :confiig => { } }, # It's same meaning of YourApp::Plugin::Bar
    #   ])
    #
    def load_plugins plugins
      load_components("plugin", plugins)
    end

    # if you customize Plugin name space. you can use this instead of load_plugins
    #
    #  app.load_components('engine', [
    #     { :module => "YourApp::Engine::Foo", :confiig => { :some_config => "foo"} },
    #     { :module => "+Bar", :confiig => { } }, # It's same meaning of YourApp::Engine::Bar
    #  ])
    #
    def load_components type, components
      components.each do |component|
        load_component type, component
      end
    end

    def load_component type, hash
      component = OpenStruct.new(hash.dup)
      mod = self.class.component_class_get(type, component.module, { :plugin_dir => self.plugin_dir })
      component.config ||= {}
      component.config[:context] = self
      instance = mod.new(component.config)
      instance.register
      logger.debug("ClassX::Pluggable: loaded #{type} #{component.module}, config=#{instance.inspect}")
    end

    # invoke registered event of +name+ with +args+. and return array of result each callback.
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

    # invoke registered event of BEFORE_xxxx and yield block and invoke hook AFTER_xxxx.
    def call_event_around name, *args, &block
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

    module Util
      def module2path mod
        mod.split(/::/).map { |s|
          s.gsub(/([A-Z][a-z]+)(?=[A-Z][a-z]*?)/, '\1_').gsub(/([A-Z])(?=[A-Z][a-z]+)/, '\1_').downcase
        }.join(File::SEPARATOR)
      end

      def nested_const_get mod
        name_spaces = mod.split(/::/)
        result = ::Object
        name_spaces.each do |const|
          result = result.const_get(const)
        end
        return result
      end

      def nested_autoload mod, path
        name_spaces = mod.split(/::/)
        target = name_spaces.pop
        tmp = ::Object
        name_spaces.each do |const|
          tmp = tmp.const_get(const)
        end
        tmp.autoload(target, path)
      end

      module_function :module2path, :nested_const_get, :nested_autoload
    end

    module ClassMethods
      include ClassX::Pluggable::Util

      def component_class_get type, name, options={}
        case name
        when ::Class
          return name
        else
          mod_name = nil
          target_name = nil
          if name =~ /\A\+([\w:]+)\z/
            target_name = $1
            mod_name = [ self, type.capitalize, target_name ].join("::")
          else
            mod_name = name
          end
          begin
            return nested_const_get(mod_name)
          rescue NameError => e
            begin
              if options[:plugin_dir]
                options[:plugin_dir].each do |path|
                  begin
                    begin
                      self.const_get(type.capitalize).autoload(name, File.expand_path(File.join(path, module2path(target_name))))
                    rescue LoadError => e
                      raise ::ClassX::Pluggable::PluginLoadError, "class: #{mod_name} is not found"
                    end
                    return nested_const_get(mod_name)
                  rescue NameError => e
                    next
                  end
                  raise NameError, "must not happened unless your code is something wrong!!"
                end
              else
                nested_autoload(mod_name, module2path(mod_name))
                nested_const_get mod_name
              end
            rescue LoadError => e
              raise ::ClassX::Pluggable::PluginLoadError, "class: #{mod_name} is not found."
            end
          end
        end
      end
    end

    def self.included klass
      klass.extend ClassMethods
    end

    # It's useful for testing.
    class MockContext
      include ClassX
      include ClassX::Pluggable
    end
  end
end
