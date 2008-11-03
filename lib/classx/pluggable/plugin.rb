require 'classx'

module ClassX
  module Pluggable
    module Plugin
      extend ClassX::Attributes

      has :context, :kind_of => ClassX::Pluggable

      module ClassMethods
        def define_events hash
          define_method :register do
            add_events hash
          end
        end
      end

      # Abstract method for calling from context instance automatically that you should implement like followings:
      #
      # def register
      #   add_event('SOME_EVENT', 'on_some_event')
      # end
      #
      # def on_some_event
      #   # do something.
      # end
      #
      def register
        raise NotImprementedError
      end

      def inspect
        hash = self.to_hash
        hash.delete("context")
        "#{self.class}: #{hash.inspect}"
      end

      private

      def self.included klass
        klass.extend(ClassMethods)
      end

      def add_event name, meth
        self.context.add_event(name, self, meth)
      end

      def add_events hash
        hash.each do |event, meth|
          add_event(event, meth)
        end
      end

      module AutoRegister
        EVENT_REGEX = /\Aon_(.+)\z/

        def register
          methods.map {|meth| meth.to_s }.grep(EVENT_REGEX).each do |meth|
            meth =~ EVENT_REGEX
            add_event $1.upcase, meth
          end
        end
      end
    end
  end
end
