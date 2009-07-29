# -*- coding: utf-8 -*-
# -*- ruby -*-

require 'spec/spec_helper'
require 'spec/api_test_helper'

describe 'VersionList' do
  include ApiTestHelper

  before(:all) do 
    # Put some data in there, damnit !
    yaml = <<'END'
--- 
:api_version: 1
:contents_columns: 
- :content_type
- :content_key
- :language
- :country
- :brand
- :application
- :data
:contents: 
- - phrase
  - new_loan
  - en
  - _
  - _
  - _
  - "new loan"
- - phrase
  - new_loan
  - es
  - _
  - _
  - _
  - "nuevo préstamo"
- - email
  - new_loan
  - en
  - _
  - _
  - cnuapp
  - |-
    subject: Hello {{customer.email}}
    body: Your loan is ready.

END
    api = load_yaml yaml

  end
  it 'should record when a piece of content changes (and create new VL to do so if needed)' do
    vl = nil
    proc = lambda do | |
      vl ||=
        VersionList.new(:comment => "test case")
    end

    lambda{
    VersionList.track_changes_in(proc) do
      c = Content.find(:first)
      c.data = c.data + ": changed!"
      c.save!
      
      #puts VersionList.current.inspect
    end
    }.should change{ VersionList.count }.by(1)
    
    #puts vl.content_versions.inspect
  end

  it 'should record the creation of a content_key' do
    vl = VersionList.new(:comment => 'test case')
    lambda{
      VersionList.track_changes_in( vl ) do
        # prime candidate for factory method
        ck = ContentKey.create!( :code => 'test98', :content_type => ContentType[:phrase], :uuid => Contenter::UUID.generate_random )
      end
    }.should change{ vl.content_key_versions.count }.by(1)
  end

  describe "Point-in-time version lists" do

    it 'should record all contents at the time of their creation' do
      vl = VersionList.create(:point_in_time => Time.now, :comment => 'test case')
      vl.content_versions.size.should == Content.count
      vl.content_key_versions.size.should == ContentKey.count
    end

    it 'should ignore contents created after the time of their creation' do
      vl = VersionList.create(:point_in_time => Time.now-10.year, :comment => 'test case')
      vl.content_versions.size.should == 0
      vl.content_key_versions.size.should == 0
    end

    it 'should be unaffected by other PIT VLs' do
      vl = VersionList.create(:point_in_time => Time.now-10.year, :comment => 'test case')
      vl_c = vl.content_versions.map{|x| x.id}.sort
      vl_ck = vl.content_key_versions.map{|x| x.id}.sort

      c = Content.find(:first)
      c.data = c.data + ": changed!"
      c.save!

      vl = vl.class.find(vl.id)
      vl.content_versions.map{|x| x.id}.sort.should == vl_c
      vl.content_key_versions.map{|x| x.id}.sort.should == vl_ck
    end

    it 'should be visible from its Content::Version and ContentKey::Version objects' do
      vl = VersionList.create(:point_in_time => Time.now, :comment => 'test case')
      vl.content_versions.each do | cv |
        cv.version_lists.should include(vl)
      end
      vl.content_key_versions.each do | ckv |
        ckv.version_lists.should include(vl)
      end
    end

  end

end


