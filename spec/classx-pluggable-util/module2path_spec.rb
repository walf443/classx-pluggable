require File.join(File.dirname(__FILE__), '..', 'spec_helper')

begin
  require 'spec/fixture'

  describe ClassX::Pluggable::Util, ".module2path" do
    with_fixtures :mod => :path do
      it "should change :mod to :path " do |mod, path|
        ClassX::Pluggable::Util.module2path(mod).should == path
      end

      set_fixtures([
        [ "Foo"             => "foo" ],
        [ "Foo::Bar"        => "foo/bar" ],
        [ "Foo::URI"        => "foo/uri" ],
        [ "Foo::CamelCase"  => "foo/camel_case" ],
        [ "CamelCamelCase"  => "camel_camel_case" ],
        [ "Foo::OpenURI"    => "foo/open_uri" ],
        [ "Foo::URIOpen"    => "foo/uri_open" ],
        [ "Foo::Open_URI"   => "foo/open_uri" ],
        [ "Foo::B_B"        => "foo/b_b" ],
        [ "Foo::B2B"        => "foo/b2b" ],
        [ "CmlCml::CmlCml"  => "cml_cml/cml_cml" ],
        [ "Foo::Bar::Baz"   => "foo/bar/baz" ],
      ])
    end
  end
rescue LoadError => e
  warn "skip this spec because of #{e.message.inspect}. if you want to run, please install rspec-fixture."
end
