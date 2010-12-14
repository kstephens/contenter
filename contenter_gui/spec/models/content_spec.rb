# -*- coding: utf-8 -*-
# -*- ruby -*-
#require 'test_helper'
require 'spec/spec_helper'

describe "Content" do

  before(:each) do 
    UserTracking.current_user = '__test__'
    UserTracking.default_user = '__test__'
  end

  it 'should error on invalid mime_types.' do
    ContentType[:phrase].mime_type.should == MimeType[:'text/*']

    ck = ContentKey.create!(:code => "test #{__FILE__}:#{__LINE__}", 
                            :content_type => ContentType[:phrase],
                            :name => '', :description => ''
                                                      )
    
    lambda do
      c = Content.create!(:content_key => ck,
                          :language => Language[:_],
                          :country => Country[:_],
                          :brand => Brand[:test],
                          :application => Application[:_],
                          :mime_type => MimeType[:'image/png'],
                          :data => 'asdfkljasdlkfjsd'
                                                      )
    end.should raise_error(ActiveRecord::RecordInvalid)
  end
end # describe
