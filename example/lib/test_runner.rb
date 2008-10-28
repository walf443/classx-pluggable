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
    around_event(:ALL, self) do

      test_cases.each do |tc|
        _do_test(tc)
      end

    end
  end

  # it's dummy
  def _do_test tc
    around_event(:EACH, self, tc) do
      sleep(0.1)
    end
  end

  module Plugin
    class SetupFixture
      include ClassX
      include ClassX::Pluggable::Plugin
      include ClassX::Pluggable::Plugin::AutoRegister

      # without C::P::P::AutoRegister
      # you can do followings:
      #
      # define_events({
      #   :BEFORE_ALL => :on_before_all,
      #   :AFTER_ALL  => :on_after_all,
      # })

      def on_around_all c
        c.logger.info "#{self.class}: Setup Fixture"
        yield
        c.logger.info "#{self.class}: Clear Fixture"
      end
    end

    class TestTimer
      include ClassX
      include ClassX::Pluggable::Plugin
      include ClassX::Pluggable::Plugin::AutoRegister

      # without C::P::P::AutoRegister
      # you can do followings:
      #
      #   :BEFORE_ALL     => :on_before_all,
      #   :AFTER_ALL      => :on_after_all,
      #   :BEFORE_EACH  => :on_before_each,
      #   :AFTER_EACH   => :on_after_each,
      # })

      def on_around_all c
        c.logger.info "#{self.class}: total: start timer"
        @test_suite_timer = Time.now

        yield

        diff = Time.now - @test_suite_timer
        c.logger.info "#{self.class}: total: #{diff.to_f} sec."
      end

      def on_around_each c, test
          c.logger.info "#{self.class}: test #{test}: start timer"
          @test_timer = Time.now
          yield

          diff = Time.now - @test_timer

          c.logger.info "#{self.class}: test #{test}: #{diff.to_f} sec."
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
