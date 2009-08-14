# -*- coding: utf-8 -*-
# -*- ruby -*-

require 'spec/spec_helper'
require 'spec/api_test_helper'

describe 'VersionList' do
  include ApiTestHelper

  def this_line
    caller.first.to_s
  end

  before(:each) do
    UserTracking.default_user = '__test__'
  end
    
  before(:all) do 
    UserTracking.default_user = '__test__'

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


  it 'should record when a piece of content changes (and create new VL to do so as needed)' do
    begin
    #$stderr.puts "\nYO #{__FILE__} #{__LINE__}"
    #VersionList::ChangeTracking.debug = true
    #VersionList.debug = true
    #RAILS_DEFAULT_LOGGER.error "\nYO #{__FILE__} #{__LINE__}"

    vl = nil
    proc = lambda {
      vl ||=
        begin
          vl = VersionList.new(:comment => this_line)
          # $stderr.puts "  Created new VL = #{vl.inspect}"
          vl
        end
    }

    lambda {
      VersionList.track_changes.should == true
      VersionList.current.size.should == 0
      VersionList.track_changes_in(proc) do
        VersionList.track_changes.should == true
        VersionList.current.size.should == 1

        c = Content.find(:first)
        # require 'pp'; pp c.attributes
        c_data_new = c.data = c.data + ": changed at #{this_line}"
        c.changed?.should == true
        c.altered?.should == true
        c.version_condition_met?.should == true
        c.save!
        c.errors.empty?.should == true
       
        # require 'pp'; pp c.attributes

        c = c.class.find(c.id)
        c.data.should == c_data_new

        vl.should_not == nil
        vl.id.should_not == nil
        vl.size.should == 1
        puts vl.content_versions.inspect
      end
    }.should change{ VersionList.count }.by(1)
    VersionList.current.size.should == 0 
   
  ensure
    # $stderr.puts "\nDONE #{__FILE__} #{__LINE__}"
    VersionList::ChangeTracking.debug = false
    VersionList.debug = false
  end
  end

  it 'should record the creation of a content_key' do
    vl = VersionList.new(:comment => this_line)
    lambda {
      VersionList.current.size.should == 0
      VersionList.track_changes_in( vl ) do
        VersionList.current.size.should == 1
        # prime candidate for factory method
        ck = ContentKey.create!( :code => "test#{__LINE__}", 
                                 :content_type => ContentType[:phrase], 
                                 :uuid => Contenter::UUID.generate_random )
      end
      VersionList.current.size.should == 0
    }.should change{ vl.content_key_versions.count }.by(1)
  end

  describe "Point-in-time version lists" do

    it 'should record all contents at the time of their creation' do
      vl = VersionList.create(:point_in_time => Time.now, :comment => this_line)
      vl.content_versions.size.should == Content.count
      vl.content_key_versions.size.should == ContentKey.count
    end

    it 'should ignore contents created after the time of their creation' do
      vl = VersionList.create(:point_in_time => Time.now-10.year, :comment => this_line)
      vl.content_versions.size.should == 0
      vl.content_key_versions.size.should == 0
    end

    it 'should be unaffected by other PIT VLs' do
      vl = VersionList.create(:point_in_time => Time.now-10.year, :comment => this_line)
      vl_c = vl.content_versions.map{|x| x.id}.sort
      vl_ck = vl.content_key_versions.map{|x| x.id}.sort

      c = Content.find(:first)
      c_data_old = c.data.dup

      c.data = c.data + ": changed at #{this_line}"

      c_data_new = c.data.dup
      c_data_old.should_not == c_data_new

      c.save!

      vl = vl.class.find(vl.id)
      vl.content_versions.map{|x| x.id}.sort.should == vl_c
      vl.content_key_versions.map{|x| x.id}.sort.should == vl_ck
    end

    it 'should be visible from its Content::Version and ContentKey::Version objects' do
      vl = VersionList.create(:point_in_time => Time.now, :comment => this_line)
      vl.content_versions.each do | cv |
        cv.version_lists.should include(vl)
      end
      vl.content_key_versions.each do | ckv |
        ckv.version_lists.should include(vl)
      end
    end

  end

end


