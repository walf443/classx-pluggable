$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))

require 'test_runner'

require 'yaml'
config = YAML.load( ARGF )
app = TestRunner.new(config["global"].merge({ :test_cases => [:foo, :bar, :baz]})) # dummy
app.load_plugins(config["plugins"])

app.run
