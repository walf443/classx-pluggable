require File.join(File.dirname(__FILE__), 'spec_helper')
require 'logger'
require 'stringio'

def example_check name
  base_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  target_runner = File.join(base_dir, 'example', name, 'bin', "#{name}.rb")

  describe "example", name do
    it "should not raise Exception" do
      lambda {
        $logger = Logger.new(StringIO.new)
        load target_runner
      }.should_not raise_error(Exception)
    end
  end
end

example_check "test_runner"
