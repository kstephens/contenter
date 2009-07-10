# -*- ruby -*-

require 'spec/spec_helper'

describe 'RevisionList' do

  it 'should record when a piece of content changes (and create new RL to do so if needed)' do
    rl = nil
    proc = lambda do | |
      rl ||=
        RevisionList.new(:comment => "test case")
    end

    lambda{
    RevisionList.track_changes_in(proc) do
      c = Content.find(1)
      c.data = c.data + ": changed!"
      c.save!
      
      #puts RevisionList.current.inspect
    end
    }.should change{ RevisionList.count }.by(1)
    
    #puts rl.content_versions.inspect
  end

  it 'should record the creation of a content_key' do
    pending do

      rl = RevisionList.new(:comment => 'test case')
      lambda{
        RevisionList.track_changes_in( rl ) do
          # prime candidate for factory method
          ck = ContentKey.create( :code => 'test', :uuid => Contenter::UUID.generate_random )
        end
      }.should change{ rl.content_key_versions.count }.by(1)
      
    end
  end

end


