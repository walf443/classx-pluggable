require 'classx'
require 'classx/validate'
$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../../../../lib')))
require 'classx/pluggable/plugin'

class TestRunner
  module Plugin
    class SetupFixture
      include ClassX
      include ClassX::Pluggable::Plugin
      include ClassX::Pluggable::Plugin::AutoRegister

      # without C::P::P::AutoRegister
      # you can do followings:
      #
      # define_events({
      #   :AROUND_ALL => :on_around_all,
      # })

      def on_around_all param
        param = ClassX::Validate.validate param do
          has :logger
        end

        param.logger.info "#{self.class}: Setup Fixture"
        yield
        param.logger.info "#{self.class}: Clear Fixture"
      end
    end
  end
end
