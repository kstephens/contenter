#require 'mime_type'
#require 'model_cache'

describe 'ModelCache' do
  it "should not cache MimeType[] by default" do
    ModelCache.reset!
    ModelCache.current.size.should == 0
    o1 = MimeType['text/plain']
    o2 = MimeType['text/plain']
    o1.object_id.should_not == o2.object_id
  end
  
  it "should MimeType[] after create!" do
    ModelCache.reset!
    ModelCache.create!
    ModelCache.current.size.should == 1
    ModelCache.enabled.should == true
    o1 = MimeType['text/plain']
    o2 = MimeType['text/plain']
    o1.object_id.should == o2.object_id

    o2 = MimeType['text/plain']
    o1.object_id.should == o2.object_id

    ModelCache.reset!
    ModelCache.create!

    o2 = MimeType['text/plain']
    o1.object_id.should_not == o2.object_id
  end

  it "should cache MimeType[] during with_current" do
    o1 = o2 = nil

    ModelCache.reset!
    ModelCache.with_current do | cache |
      ModelCache.current.size.should == 1
      cache.n_flush.keys.empty?.should == true

      o1 = MimeType['text/plain']
      o2 = MimeType['text/plain']
      o1.object_id.should == o2.object_id

      o2 = MimeType['text/plain']
      o1.object_id.should == o2.object_id

      cache.n_flush.keys.empty?.should == true
    end

    o2 = MimeType['text/plain']
    o1.object_id.should_not == o2.object_id
  end
end # describe

