require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe ClassX::Pluggable::Util, '.nested_const_get' do
  include ClassX::Pluggable::Util
  before :all do

    one_level_const, two_level_const, three_level_const = nil
    Object.class_eval do
      one_level_const = Module.new
      const_set "ClassXPluggableNestedConstGet", one_level_const
      one_level_const.class_eval do
        two_level_const = Module.new
        const_set "Plugin", two_level_const
        two_level_const.class_eval do
          three_level_const = Module.new
          const_set "Foo", three_level_const
        end
      end
    end

    @one_level_const = one_level_const
    @two_level_const = two_level_const
    @three_level_const = three_level_const
  end

  it "should not raise error on one level const_get" do
    const = nil
    lambda { const = nested_const_get("ClassXPluggableNestedConstGet") }.should_not raise_error
    const.should == @one_level_const
  end

  it "should not raise error on one two level nested const_get" do
    const = nil
    lambda { const = nested_const_get("ClassXPluggableNestedConstGet::Plugin") }.should_not raise_error
    const.should == @two_level_const
  end

  it "should not raise error on one three level nested const_get" do
    const = nil
    lambda { const = nested_const_get("ClassXPluggableNestedConstGet::Plugin::Foo") }.should_not raise_error
    const.should == @three_level_const
  end

  it "should raise NameError on undefined nested constant" do
    const = nil
    lambda { const = nested_const_get("ClassXPluggableNestedConstGet::Plugin::Bar") }.should raise_error(NameError)
  end
end
