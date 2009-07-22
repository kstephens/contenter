# -*- ruby -*-

require 'spec/spec_helper'

describe 'VersionList' do

  it 'should record when a piece of content changes (and create new RL to do so if needed)' do
    rl = nil
    proc = lambda do | |
      rl ||=
        VersionList.new(:comment => "test case")
    end

    lambda{
    VersionList.track_changes_in(proc) do
      c = Content.find(1)
      c.data = c.data + ": changed!"
      c.save!
      
      #puts VersionList.current.inspect
    end
    }.should change{ VersionList.count }.by(1)
    
    #puts rl.content_versions.inspect
  end

  it 'should record the creation of a content_key' do
    rl = VersionList.new(:comment => 'test case')
    lambda{
      VersionList.track_changes_in( rl ) do
        # prime candidate for factory method
        ck = ContentKey.create!( :code => 'test98', :content_type => ContentType[:phrase], :uuid => Contenter::UUID.generate_random )
      end
    }.should change{ rl.content_key_versions.count }.by(1)
  end

end


