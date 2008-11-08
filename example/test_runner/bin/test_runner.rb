$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))

require 'test_runner'

require 'yaml'
conf = ARGV[0] || File.join(File.dirname(__FILE__), '..', 'conf/config.yaml')

config = nil
File.open(conf) do |f|
  config = YAML.load(f.read)
end
app = TestRunner.new(config["global"].merge({ :test_cases => [:foo, :bar, :baz]})) # dummy
app.load_plugins(config["plugins"])

app.run
