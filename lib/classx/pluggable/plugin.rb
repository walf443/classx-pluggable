require 'classx'

module ClassX
  module Pluggable
    module Plugin
      extend ClassX::Attributes

      has :context

      # Abstract method for calling from context instance automatically that you should implement like followings:
      #
      # def register
      #   self.context.add_event('SOME_EVENT', self) do |args|
      #     # do something
      #   end
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

    end
  end
end
