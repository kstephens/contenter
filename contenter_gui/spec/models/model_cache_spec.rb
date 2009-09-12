# require 'model_cache'

describe 'ModelCache' do
  if true
  it "should not cache User[] by default" do
    ModelCache.reset!
    ModelCache.current.size.should == 0
    o1 = User['__test__']
    o2 = User['__test__']
    o1.object_id.should_not == o2.object_id
  end
  
  it "should User[] after create!" do
    ModelCache.reset!
    ModelCache.create!
    ModelCache.current.size.should == 1
    ModelCache.enabled.should == true
    o1 = User['__test__']
    o2 = User['__test__']
    o1.object_id.should == o2.object_id

    o2 = User['__test__']
    o1.object_id.should == o2.object_id

    ModelCache.reset!
    ModelCache.create!

    o2 = User['__test__']
    o1.object_id.should_not == o2.object_id
  end

  it "should cache User[] during with_current" do
    o1 = o2 = nil

    ModelCache.reset!
    ModelCache.with_current do | cache |
      ModelCache.current.size.should == 1
      cache.n_flush.keys.empty?.should == true

      o1 = User['__test__']
      o2 = User['__test__']
      o1.object_id.should == o2.object_id

      o2 = User['__test__']
      o1.object_id.should == o2.object_id

      cache.n_flush.keys.empty?.should == true
    end

    o2 = User['__test__']
    o1.object_id.should_not == o2.object_id
  end

  end
end # describe

