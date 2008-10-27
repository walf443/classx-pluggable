require 'classx'
require 'ostruct'

module ClassX
  module Pluggable
    extend ClassX::Attributes
    extend ClassX::Role::Logger

    DEFAULT_PLUGIN_DIR = File.expand_path(File.join(File.dirname(__FILE__), File.basename(__FILE__).sub(/\.rb$/, ''), 'plugin'))

    has :__classx_pluggable_events_of,
        :lazy    => true,
        :no_cmd_option  => true,
        :default => proc { Hash.new }

    has :__classx_pluggable_plugin_dir,
        :lazy   => true,
        :no_cmd_option  => true,
        :default => proc {
          [
            File.expand_path(File.join(File.dirname(__FILE__), File.basename(__FILE__).sub(/\.rb$/, ''), 'plugin')),
            DEFAULT_PLUGIN_DIR
          ].uniq
        }

    def add_event name, plugin, meth
      name = name.to_s
      self.__classx_pluggable_events_of[name] ||= []
      self.__classx_pluggable_events_of[name] << { :plugin => plugin, :method => meth }
    end

    def load_plugins plugins
      plugins.each do |plugin|
        load_plugin plugin
      end
    end

    def load_plugin hash
      plugin = OpenStruct.new(hash)
      mod = plugin_class_get(plugin.module)
      plugin.config ||= {}
      original_config = plugin.config.dup
      plugin.config[:context] = self
      mod.new(plugin.config).register
      logger.debug("ClassX::Pluggable: loaded plugin #{plugin.module}, config=#{original_config.inspect}")
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

    private

    def after_init
      self.__classx_pluggable_plugin_dir.each do |path|
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

    def plugin_class_get name
      case name
      when ::Class
        return name
      else
        name_spaces = name.split(/::/)
        result = ::Object
        begin
          name_spaces.each do |const|
            result = result.const_get(const)
          end
          return result
        rescue NameError => e
          raise LoadError, "module: #{name} is not found."
        end
      end
    end
  end
end
