# -*- ruby -*-

# Test metadata:
# TEST_CONFIG_BEGIN
# enabled: true
# note: none
# owners: kurt
# tags: unit Contenter::Api::HashTtl spec_server
# TEST_CONFIG_END

# Test environment:
require 'contenter/test/helper'

# Test target:
require 'contenter/api/hash_ttl'

# Test support:
# NONE

describe 'Contenter::Api::HashTtl' do
  def create_hash
    h = Contenter::Api::HashTtl.new
    h.instance_variable_get('@now').should == nil
    # h.ttl.should == 0
    # h.ttl_bias.should == false
    h.ttl = 2
    h.ttl_bias = 0

    h['a'] = 1
    h['b'] = 2

    h.instance_variable_get('@now').should_not == nil
    h.now.should_not == nil

    h.keys.sort.should == ['a', 'b']
    h.values.sort.should == [ 1,  2 ]

    h['a'].should == 1
    h['b'].should == 2
    h['c'].should == nil

    h
  end

  it 'should retrieve values' do
    h = create_hash
  end

  it 'should expire old values' do
    h = create_hash

    sleep 4

    expired = h.check_time_to_live!
    expired.sort.should == [ 'a', 'b' ]

    h.keys.should == [ ]
    h.values.should == [ ]

    h['a'].should == nil
    h['b'].should == nil
    h['c'].should == nil
  end

end # describe

