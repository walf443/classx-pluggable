require 'classx'

module ClassX
  module Pluggable
    module Plugin
      extend ClassX::Attributes

      has :context

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
        hash.delete(:context)
        "#{self.class}: #{self.to_hash}"
      end

      private

      def add_event name, meth
        self.context.add_event(name, self, meth)
      end

      def add_events hash
        hash.each do |event, meth|
          add_event(event, meth)
        end
      end
    end
  end
end
