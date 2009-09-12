# -*- coding: utf-8 -*-
# -*- ruby -*-
#require 'test_helper'
require 'spec/spec_helper'

describe "Content/ContentStatus" do

  before(:each) do 
    UserTracking.current_user = '__test__'
    UserTracking.default_user = '__test__'
  end

  it 'should handle content_status tracking.' do
    ck = ContentKey.create(:code => "test #{__FILE__}:#{__LINE__}", 
                           :content_type => ContentType[:phrase],
                           :name => '', :description => ''
                           )

    c = Content.create(:content_key => ck,
                       :language => Language[:_],
                       :country => Country[:_],
                       :brand => Brand[:_],
                       :application => Application[:_],
                       :mime_type => MimeType[:_],
                       :data => 'new'
                       )

    #puts "\n#{__FILE__}"
    #puts ck.inspect
    #puts c.inspect

    c.content_status.code.should == 'created'

    c.versions.size.should == 1
    cv1 = c.versions.latest
    cv1.version.should == 1
    cv1.content_status.code.should == c.content_status.code

    # Save again with no changes.
    # puts c.changes.inspect
    c.altered?.should == false
    lambda{ c.save! }.should_not change{ c.versions.size }

    # Force a change.
    # Ensure that new Content::Version was saved,
    # and content_status is now modified.
    c = c.class.find(c.id)
    c.content_status.code.should == 'created'
    c.data = 'changed'
    c.save!

    c.versions.size.should == 2
    cvx = c.versions.latest
    cvx.version.should == 2
    cvx.id.should_not == cv1.id
    c.content_status.code.should == 'modified'
    cvx.content_status.code.should == c.content_status.code

    # Forces setting the status to :approved (not a version-inducing change)
    lambda{ c.set_content_status! :approved }.should_not change{ c.versions.size }

    cvx = c.versions.latest
    c.content_status.code.should == 'approved'
    cvx.content_status.code.should == c.content_status.code

    # Force another change.
    # Ensure that new Content::Version was saved,
    # and content_status is now :modified.
    c.data += ' again'
    c.save!
    
    c.versions.size.should == 3
    c.content_status.code.should == 'modified'
    cvx = c.versions.latest
    cvx.content_status.code.should == c.content_status.code

  end


end

