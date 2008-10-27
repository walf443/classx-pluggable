require 'classx'
$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../../lib')))
require 'classx/pluggable'
require 'classx/pluggable/plugin'

class TestRunner
  include ClassX
  include ClassX::Role::Logger
  include ClassX::Pluggable

  has :test_cases

  def run
    call_event(:BEFORE_ALL, self)

    test_cases.each do |tc|
      _do_test(tc)
    end

    call_event(:AFTER_ALL, self)
  end

  # it's dummy
  def _do_test tc
    call_event(:BEFORE_EACH, self)

    sleep(0.1)
    call_event(:AFTER_EACH, self)
  end

  module Plugin
    class SetupFixture
      include ClassX
      include ClassX::Pluggable::Plugin

      def register
        # dummy
        self.context.add_event(:BEFORE_ALL, self) do |c|
          on_before_all c
        end

        # dummy
        self.context.add_event(:AFTER_ALL, self) do |c|
          on_after_all c
        end
      end

      private

      def on_before_all c
          c.logger.info "Setup Fixture"
      end

      def on_after_all c
          c.logger.info "Clear Fixture"
      end
    end

    class TestTimer
      include ClassX
      include ClassX::Pluggable::Plugin

      def register
        self.context.add_event(:BEFORE_ALL, self) do |c|
          on_before_all c
        end
        self.context.add_event(:AFTER_ALL, self) do |c|
          on_after_all c
        end

        self.context.add_event(:BEFORE_EACH, self) do |c|
          on_before_each c
        end

        self.context.add_event(:AFTER_EACH, self) do |c|
          on_after_each c
        end
      end

      private

      def on_before_all c
        @test_suite_timer = Time.now
      end

      def on_after_all c
        diff = Time.now - @test_suite_timer
        c.logger.info "total: #{diff.to_f} sec."
      end

      def on_before_each c
          @test_timer = Time.now
      end

      def on_after_each c
          diff = Time.now - @test_timer

          c.logger.info "test: #{diff.to_f} sec."
      end
    end
  end
end

if $0 == __FILE__
  app = TestRunner.new(:test_cases => [:foo, :bar, :baz], :log_level => 'debug') # dummy
  app.load_plugins([
    { :module => TestRunner::Plugin::SetupFixture, },
    { :module => "TestRunner::Plugin::TestTimer", },
  ])

  app.run
end
