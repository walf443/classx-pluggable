require 'classx'
require 'classx/validate'
$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../../../../lib')))
require 'classx/pluggable/plugin'

class TestRunner
  module Plugin
    class TestInfo
      include ClassX
      include ClassX::Pluggable::Plugin
      include ClassX::Pluggable::Plugin::AutoRegister

      has :template

      def on_before_each param
        param = ClassX::Validate.validate param do
          has :logger
          has :test
        end

        info = self.template % [ param.test ]
        param.logger.info "#{self.class}: #{info}"

        info
      end
    end
  end
end
