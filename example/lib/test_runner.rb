require 'classx'
require 'classx/validate'
$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../../lib')))
require 'classx/pluggable'
require 'classx/pluggable/plugin'

class TestRunner
  include ClassX
  include ClassX::Role::Logger
  include ClassX::Pluggable

  has :test_cases

  def run
    around_event(:ALL, :logger => logger) do

      test_cases.each do |tc|
        _do_test(tc)
      end

    end
  end

  # it's dummy
  def _do_test tc
    around_event(:EACH, :logger => logger, :test => tc) do
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
        @test_suite_timer = Time.now

        yield

        diff = Time.now - @test_suite_timer
        param.logger.info "#{self.class}: total: #{diff.to_f} sec."

        diff
      end

      def on_around_each param
        param = ClassX::Validate.validate param do
          has :logger
          has :test
        end

        param.logger.info "#{self.class}: test #{param.test}: start timer"
        @test_timer = Time.now
        yield

        diff = Time.now - @test_timer

        param.logger.info "#{self.class}: test #{param.test}: #{diff.to_f} sec."

        diff
      end
    end

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

if $0 == __FILE__
  app = TestRunner.new(
    :test_cases => [:foo, :bar, :baz],
    :log_level => 'debug',
    :__classx_pluggable_check_event => true,
    :__classx_pluggable_events_of => {
      "BEFORE_EACH" => [],
      "AROUND_ALL" => [],
      "AROUND_EACH" => [],
    }
  ) # dummy
  app.load_plugins([
    { :module => TestRunner::Plugin::SetupFixture, },
    { :module => "TestRunner::Plugin::TestTimer", },
    { :module => "TestRunner::Plugin::TestInfo", :config => { :template => "start test %s" }},
    { :module => "TestRunner::Plugin::TestInfo", :config => { :template => "you can also output other info for %s" }},
  ])

  app.run

  # example of testing plugin
  require 'spec'
  require 'stringio'
  describe TestRunner::Plugin::TestInfo do
    before do
      @plugin = TestRunner::Plugin::TestInfo.new({
        :context => ClassX::Pluggable::MockContext.new,
        :template => "test is %s"
      })
    end

    it "should hoook :BEFORE_EACH" do
      @plugin.on_before_each(:logger => Logger.new(StringIO.new), :test => "hoge").should == "test is hoge"
    end
  end
end
