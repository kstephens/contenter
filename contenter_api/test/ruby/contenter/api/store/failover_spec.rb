# -*- ruby -*-

# Test metadata:
# TEST_CONFIG_BEGIN
# enabled: true
# note: none
# owners: kurt
# tags: unit Contenter::Api
# TEST_CONFIG_END

# Test environment:
require 'contenter/test/helper'

# Test target:
require 'contenter/api/store/failover'

# Test support:
require 'contenter/api/test'


describe 'Contenter::Api' do
  def setup
    Contenter::Api::Test.setup!
    @c = Contenter::Api.instance(:cache_ttl => 1, :cache_ttl_bias => 0)
    @s1 = Contenter::Api::Store::Test.new(:name => :test1)
    @s2 = Contenter::Api::Store::Test.new(:name => :test2)
    @s = Contenter::Api::Store::Failover.
      new(:delegates => [
                         { :delegate => @s1, :blacklist_interval => 10, },
                         { :delegate => @s2, },
                        ]
          )       
    @c.type(:test).store = @s
    @c.preload!
    @c.reload!
    @c.flush_fallback_cache!
  end

  before(:each) do
    setup
    Selector.default = {
      :application => :test,
      :brand => :test,
      :country => :US,
      :language => :en,
    }
    Selector.current = nil
  end


  it 'should locate content by type' do
    @s1.force_error = @s2.force_error = nil

    v = @c.get(:test, :hello)

    v.should_not == nil
    v.should == 'hello'
  end


  it 'should failover to other store' do
    @s1.force_error = @s2.force_error = nil
    @s1.error_message = @s2.error_message = nil

    @s1.force_error = ArgumentError

    v = @c.get(:test, :hello)

    v.should == 'hello'

    @s1.error_message.should == "key :hello sel Contenter::Api::Selector[:test, :test, :US, :en]"
    @s2.error_message.should == nil
  end


end # describe

