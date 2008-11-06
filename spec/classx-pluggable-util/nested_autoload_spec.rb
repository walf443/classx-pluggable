require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe ClassX::Pluggable::Util, '.nested_autoload' do
  include ClassX::Pluggable::Util

  before :all do
    one_level_const, two_level_const, three_level_const = nil
    Object.class_eval do
      one_level_const = Module.new
      const_set "ClassXPluggableNestedAutoload", one_level_const
      one_level_const.class_eval do
        two_level_const = Module.new
        const_set "Plugin", two_level_const
        two_level_const.class_eval do
        end
      end
    end

    @one_level_const = one_level_const
    @two_level_const = two_level_const
    @three_level_const = three_level_const
  end

  it "should autoload non-nested module" do
    Object.autoload?("Foo").should == nil
    nested_autoload("Foo", "hoge/fuga")
    Object.autoload?("Foo").should == "hoge/fuga"
    lambda { Object.const_get("Foo") }.should raise_error(LoadError)
    lambda { Object.const_get("Foo") }.should raise_error(NameError)
  end

  it "should autoload two level nested module" do
    @one_level_const.autoload?("Bar") == nil
    nested_autoload("ClassXPluggableNestedAutoload::Bar", "hoge/hoge1")
    @one_level_const.autoload?("Bar").should == "hoge/hoge1"
    lambda { @one_level_const.const_get("Bar") }.should raise_error(LoadError)
    lambda { @one_level_const.const_get("Bar") }.should raise_error(NameError)
  end

  it "should autoload two level nested module" do
    @two_level_const.autoload?("Baz") == nil
    nested_autoload("ClassXPluggableNestedAutoload::Plugin::Baz", "foo/bar/baz")
    @two_level_const.autoload?("Baz").should == "foo/bar/baz"
    lambda { @two_level_const.const_get("Baz") }.should raise_error(LoadError)
    lambda { @two_level_const.const_get("Baz") }.should raise_error(NameError)
  end
end

