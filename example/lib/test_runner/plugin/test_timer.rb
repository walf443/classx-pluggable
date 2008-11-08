require 'classx'
require 'classx/validate'
$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../../../../lib')))
require 'classx/pluggable/plugin'


class TestRunner
  module Plugin
    class TestTimer
      include ClassX
      include ClassX::Pluggable::Plugin
      include ClassX::Pluggable::Plugin::AutoRegister

      # without C::P::P::AutoRegister
      # you can do followings:
      #
      # define_events({
      #   :AROUND_ALL     => :on_around_all,
      #   :AROUND_EACH    => :on_arond_each,
      # })

      def on_around_all param
        param = ClassX::Validate.validate param do
          has :logger
        end

        param.logger.info "#{self.class}: total: start timer"
        test_suite_timer = Time.now

        yield

        diff = Time.now - test_suite_timer
        param.logger.info "#{self.class}: total: #{diff.to_f} sec."

        diff
      end

      def on_around_each param
        param = ClassX::Validate.validate param do
          has :logger
          has :test
        end

        param.logger.info "#{self.class}: test #{param.test}: start timer"
        test_timer = Time.now
        yield

        diff = Time.now - test_timer

        param.logger.info "#{self.class}: test #{param.test}: #{diff.to_f} sec."

        diff
      end
    end
  end
end
