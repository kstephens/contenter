require 'spec/spec_helper'

describe 'User Capabilities' do

  describe 'root' do
    it 'should have the triple-star capability' do
      Capability.find_by_name('controller/*/*/*').should_not be_nil
    end
    it 'should have any capability' do
      Capability.find(:all).each do |c|
        User['root'].has_capability?(c.name).should == true
      end
      # and explicitly...
      User['root'].has_capability?('controller/<<workflow>>/<<perform_status_action>>/<<approve>>').should == true
    end
  end
end
