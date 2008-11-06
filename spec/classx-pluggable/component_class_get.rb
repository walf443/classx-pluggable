require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe ClassX::Pluggable, '.component_class_get' do
  before :all do
    module ClassXPluggableComponentClassGet
      include ClassX::Pluggable

      module Plugin
        class Foo
        end
      end
    end
  end

  it 'should not raise error when you specify module name starting with plus and ClassXPluggableComponentClassGet::Plugin::Foo is exist' do
    lambda { ClassXPluggableComponentClassGet.component_class_get("plugin", "+Foo") }.should_not raise_error(Exception)
  end
end
