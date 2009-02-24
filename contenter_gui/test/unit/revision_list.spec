
rl = nil
proc = lambda do | |
  rl ||=
    RevisionList.new(:comment => "test case")
end

RevisionList.track_changes_in(proc) do
  c = Content.find(1)
  c.data = c.data + ": changed!"
  c.save!

  puts RevisionList.current.inspect
end

puts rl.content_versions.inspect

