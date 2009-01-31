require 'capability_helper'

describe "CapabilityHelper" do
  include CapabilityHelper
  it 'should expand wildcards' do
    capability_expand('').should == [ ]
    capability_expand('foo').should == [ '*', 'foo', '+' ]
    capability_expand('foo/bar').should == [ '*/*', '*/bar', '*/+', 'foo/*', 'foo/bar', 'foo/+', '+/*', '+/bar', '+/+' ]
  end
end

