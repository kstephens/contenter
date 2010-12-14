# -*- coding: utf-8 -*-
# -*- ruby -*-
#require 'test_helper'
require 'spec/spec_helper'

describe "MimeType" do

  before(:each) do 
    UserTracking.current_user = '__test__'
    UserTracking.default_user = '__test__'
  end

  it 'should support mime_type_super and mime_type_ancestors.' do
    ModelCache.flush!(MimeType)

    MimeType[:'*/*'].mime_type_super.should == nil
    
    MimeType[:_].mime_type_super.should == MimeType[:'*/*']
    MimeType[:'text/*'].mime_type_super.should == MimeType[:'*/*']
    MimeType[:'image/*'].mime_type_super.should == MimeType[:'*/*']
    MimeType[:'audio/*'].mime_type_super.should == MimeType[:'*/*']
    
    MimeType[:'text/plain'].mime_type_super.should == MimeType[:'text/*']
    MimeType[:'image/png'].mime_type_super.should == MimeType[:'image/*']
    MimeType[:'audio/flac'].mime_type_super.should == MimeType[:'audio/*']
  end
  
  it 'each should have itself as an ancestor.' do
    MimeType.find(:all) do | o |
      o.mime_type_ancestors.include?(o).should == true
      o.mime_type_ancestors.include?(nil).should == false
    end
  end

  it 'each should not have itself as an decendent' do
    MimeType.find(:all) do | o |
      o.mime_type_decendents.include?(o).should_not == true
      o.mime_type_decendents.include?(nil).should == false
    end
  end

  it 'should have stock mime_type_ancestors.' do
    MimeType[:'text/plain'].mime_type_ancestors.map(&:to_s).should == 
      [ 'text/plain', 'text/*', '*/*' ]
    MimeType[:'image/png'].mime_type_ancestors.map(&:to_s).should == 
      [ 'image/png', 'image/*','*/*' ]
    MimeType[:'audio/flac'].mime_type_ancestors.map(&:to_s).should == 
      [ 'audio/flac', 'audio/*', '*/*' ]
  end

 it 'should have stock mime_type_decendents.' do
    MimeType[:'text/plain'].mime_type_decendents.map(&:to_s).sort.should == 
      [ ]
    MimeType[:'text/*'].mime_type_decendents.map(&:to_s).sort.should == 
      [ "text/css", "text/csv", 'text/html', 'text/plain' ]
    MimeType[:'image/*'].mime_type_decendents.map(&:to_s).sort.should == 
      [ 'image/gif', 'image/jpeg', 'image/png' ]
  end

end

