require 'classx'
require 'classx/validate'
$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../../lib')))
require 'classx/pluggable'
require 'classx/pluggable/plugin'

class TestRunner
  include ClassX
  include ClassX::Role::Logger
  include ClassX::Pluggable

  module Plugin; end

  has :test_cases

  def run
    call_event_around(:ALL, :logger => logger) do

      test_cases.each do |tc|
        _do_test(tc)
      end

    end
  end

  # it's dummy
  def _do_test tc
    call_event_around(:EACH, :logger => logger, :test => tc) do
      sleep(0.1)
    end
  end
end

