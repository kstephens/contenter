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
require 'contenter/api'

# Test support:
require 'contenter/api/test'


describe 'Contenter::Api' do
  def setup
    Contenter::Api::Test.setup!
    @c = Contenter::Api.instance(:cache_ttl => 1, :cache_ttl_bias => 0)
    @c.cache_ttl.should == 1
    @c.type(:test).store = Contenter::Api::Store::Test.new(:name => :test)
    @c.preload!
    @c.reload!
  end

  before(:all) do
    setup
  end


  it 'should locate content by type' do
    v = @c.get(:test, :hello)
    v.should_not == nil
    v.should == 'hello'
  end

  it 'should locate with a language override' do
    v = @c.get(:test, :hello, :language => :es)
    v.should_not == nil
    v.should == 'hola'
  end
 
  it 'should locate with a default language fall-back' do
    v = @c.get(:test, :hello, :language => :fr)
    v.should_not == nil
    v.should == 'hello'
  end

  it 'should locate with a Api::Selector.with() block' do
    Contenter::Api::Selector.with(:language => :es) do
      v = @c.get(:test, :hello)
      v.should_not == nil
      v.should == 'hola'
    end
  end

  it 'should raise an error on undefined content' do
    lambda { @c.get(:test, :im_a_badass_content_key_with_no_love) }.should raise_error(Contenter::Error::Unknown)
  end

  it 'should used cached content' do
    begin
      @c.get(:test, :hello).should == 'hello'
      @c.get(:test, :hello, :language => :fr).should == 'hello'
      
      # Force modification to Api::Type object's content.
      data = @c.type(:test).store.preload!
      data.class.should == Hash
      data[:en][:hello] = "howdy y'all"
      
      # Prove that cached content did not expire.
      @c.get(:test, :hello).should == 'hello'
      @c.get(:test, :hello, :language => :fr).should == 'hello'
      
    ensure
      # Restore Api::Type's content.
      data = @c.coerce_type(:test).store.preload!
    end
  end

  it 'should expire cached items after a specific amount of time' do
    begin
      # Pull cache.
      @c.get(:test, :hello).should == 'hello'
      
      # Wait for TTL cache to expire.
      sleep 3
      
      # Ensure something gets invalidated.
      expired = @c.invalidate_cache!
      expired.should > 0
      
      # Make sure that it does not need
      # to invalidate again.
      expired = @c.invalidate_cache!
      expired.should == 0
      
      # Pull through cache again.
      @c.get(:test, :hello).should == 'hello'
      
      # Wait for TTL cache to expire.
      sleep 3
      
      # Force modification to Api::Type object's content.
      data = @c.type(:test).store.preload!
      data.class.should == Hash
      data[:en][:hello] = "howdy y'all"

      # Ensure something gets invalidated.
      expired = @c.invalidate_cache!
      expired.should > 0
      
      # Make sure that it does not need
      # to invalidate again.
      expired = @c.invalidate_cache!
      expired.should == 0
      
      # Pull through cache again.
      # Value should have changed.
      @c.get(:test, :hello).should == "howdy y'all"
      
    ensure
      # Restore content.
      data = @c.type(:test).store.preload!
    end
  end


  it 'should use the fall-back cache if backend fails.' do
    begin
      # Pull through cache.
      value = @c.get(:test, :hello)
      
      # Wait for TTL cache to expire.
      sleep 3

      # Ensure something gets invalidated.
      expired = @c.invalidate_cache!
      expired.should > 0

      # Force backend error upon next get.
      @c.type(:test).store.force_error = ::Contenter::Api::Type::Test::Error
      
      # Ensure that fall-back cache was used.
      @c.get(:test, :hello).should == value
      
    ensure
      # Stop generating errors.
      @c.type(:test).store.force_error = nil
    end
  end

  it 'should reraise error on unknown content if backend fails.' do
    begin
      # Force backend error upon next get.
      @c.type(:test).store.force_error = ::Contenter::Api::Type::Test::Error

      # Ensure backend error is rethrown
      lambda { @c.get(:test, :im_a_badass_content_key_with_no_love) }.should raise_error(::Contenter::Api::Type::Test::Error)

    ensure
      # Stop generating errors.
      @c.type(:test).store.force_error = nil
    end
  end

end # describe

