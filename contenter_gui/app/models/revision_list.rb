#
# Represents a list of content revisions.
#
class RevisionList < ActiveRecord::Base
  include UserTracking

  has_many :revision_list_contents

  has_many :content_versions, :through => :revision_list_contents, :order => 'content_versions.content_id'

  # Executes block in a transaction with revision tracking.
  # Returns the new revision list with all content applied.
  # If exception is thrown, revision list is destroyed.
  # See Content::API for an example.
  def self.during(opts = { })
    rl = nil
    RevisionList.transaction do
      rl = self.new(opts) if opts
      yield
      rl.add_revisions! if opts
    end
    rl
  end


  # Adds all current Content::Versions to this RevisionList.
  def add_revisions!
    save! unless self.id
    t = RevisionListContent.table_name
    connection.execute <<"END"
DELETE FROM #{t} WHERE revision_list_id = #{self.id}
END
    connection.execute <<"END"
INSERT INTO #{t} ( revision_list_id, content_version_id )
SELECT #{self.id}, content_versions.id 
FROM contents, content_versions 
WHERE content_versions.content_id = contents.id AND content_versions.version = contents.version
END
    self
  end

end


