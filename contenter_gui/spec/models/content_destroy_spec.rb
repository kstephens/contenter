# -*- coding: utf-8 -*-
# -*- ruby -*-

require 'spec/spec_helper'
require 'spec/api_test_helper'

describe 'Content#destroy, ContentKey#destroy' do
  include ApiTestHelper

  KEY1 = 'content_delete_test1'.freeze
  KEY2 = 'content_delete_test2'.freeze

  def this_line
    caller.first.to_s
  end

  before(:all) do 
    UserTracking.default_user = '__test__'
    UserTracking.current_user = '__test__'

    
    # Put some data in there, damnit !
    yaml = <<"END"
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
  - #{KEY1.inspect}
  - en
  - _
  - _
  - test
  - "new loan"
- - phrase
  - #{KEY1.inspect}
  - es
  - _
  - _
  - test
  - "nuevo préstamo"
- - phrase
  - #{KEY2.inspect}
  - en
  - _
  - _
  - test
  - "SOMETHING"
END
    api = load_yaml yaml

  end


  it "should destroy all reminants of a Content object and it's versions and VLs" do
    ck = nil
    cs = nil # The Content objects for KEY1
    vl = nil # The version list

    begin
      #$stderr.puts "\nYO #{__FILE__} #{__LINE__}"
      #VersionList::ChangeTracking.debug = true
      #VersionList.debug = true
      #RAILS_DEFAULT_LOGGER.error "\nYO #{__FILE__} #{__LINE__}"
      
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
          
          ct = ContentType[:phrase]
          ck = ct.content_keys.by_code(KEY1)
          cs = ck.contents
          cs.size.should == 2
          
          cs.each do | c |
            c_data_new = c.data = c.data + ": changed at #{this_line}"
            c.save!
            c.errors.empty?.should == true
          end
          
          vl.size.should == cs.size
          # puts vl.content_versions.inspect
        end
      }.should change{ VersionList.count }.by(1)
      VersionList.current.size.should == 0 
      
    ensure
      # $stderr.puts "\nDONE #{__FILE__} #{__LINE__}"
      VersionList::ChangeTracking.debug = false
      VersionList.debug = false
    end

    vl.size.should == 2

    # Destroy the Content.
    c1, c2 = cs
    c1.defer_constraints do
      c1.destroy
    end
    lambda { c1.class.find(c1.id) }.should raise_error(ActiveRecord::RecordNotFound)

    # All versions of the Content should be destroyed.
    c1.versions.reload
    c1.versions.size.should == 0

    # The VersionLists should have been modified.
    vl.reload
    vl.size.should == 1
    
    # There should be no Content::Versions for the destroyed Content objects.
    Content::Version.count(:conditions => { :content_id => c1.id }).should == 0

    # Other Content should not have been affected.
    lambda { c2.class.find(c2.id) }.should_not raise_error(ActiveRecord::RecordNotFound)
    c2.versions.reload
    c2.versions.size.should == 2

    # Other ContentKeys and Content are unaffected:
    ck2 = ContentType[:phrase].content_keys.by_code(KEY2)
    ck2.versions.size.should_not == 0

    cs2 = ck2.contents
    cs2.size.should == 1
    cs2.each do | c |
      c.versions.size.should == 1
    end

  end


  it 'should destroy all reminants of a content key and all content records and their versions and VLs' do
    ck = nil
    cs = nil # The Content objects for KEY1
    vl = nil # The version list

    begin
      #$stderr.puts "\nYO #{__FILE__} #{__LINE__}"
      #VersionList::ChangeTracking.debug = true
      #VersionList.debug = true
      #RAILS_DEFAULT_LOGGER.error "\nYO #{__FILE__} #{__LINE__}"
      
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
          
          ct = ContentType[:phrase]
          ck = ct.content_keys.by_code(KEY1)
          cs = ck.contents
          cs.size.should == 2
          
          cs.each do | c |
            c_data_new = c.data = c.data + ": changed at #{this_line}"
            c.save!
            c.errors.empty?.should == true
          end
          
          vl.size.should == cs.size
          # puts vl.content_versions.inspect
        end
      }.should change{ VersionList.count }.by(1)
      VersionList.current.size.should == 0 
      
    ensure
      # $stderr.puts "\nDONE #{__FILE__} #{__LINE__}"
      VersionList::ChangeTracking.debug = false
      VersionList.debug = false
    end

    vl.size.should == 2

    # Destroy the ContentKey.
    ck.defer_constraints do
      ck.destroy
    end
    lambda { ck.class.find(ck.id) }.should raise_error(ActiveRecord::RecordNotFound)

    # All versions of the ContentKey should be destroyed.
    ck.versions.reload
    ck.versions.size.should == 0

    # The Content of the ContentKeys and all Content::Versions should be destroyed.
    cs.each do | c |
      lambda { c.class.find(c.id) }.should raise_error(ActiveRecord::RecordNotFound)
      # There should be no Content::Versions for the destroyed Content objects.
      Content::Version.count(:conditions => { :content_id => c.id }).should == 0
    end

    # The VersionList should have been emptied.
    vl.reload
    vl.size.should == 0
    
    # Other ContentKeys and Content are unaffected:
    ck2 = ContentType[:phrase].content_keys.by_code(KEY2)
    ck2.versions.size.should_not == 0

    cs2 = ck2.contents
    cs2.size.should == 1
    cs2.each do | c |
      c.versions.size.should == 1
    end

  end


end # describe


