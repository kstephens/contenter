#
# Represents a list of content revisions.
#
class RevisionList < ActiveRecord::Base
  include UserTracking

  has_many :revision_list_contents, :order => 'content_versions.content_id'

  has_many :content_versions, :through => :revision_list_contents, :order => 'content_versions.content_id'

  # Executes block in a transaction with revision tracking.
  # Returns the new revision list of all current content revisions.
  # If exception is thrown, revision list is aborted.
  # See Content::API for an example.
  def self.after(opts = { })
    rl = nil
    RevisionList.transaction do
      rl = self.new(opts) if opts
      yield
      rl.set_current_revisions! if opts
    end
    rl
  end


  # Adds all current Content::Versions to this RevisionList.
  def set_current_revisions!
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


  # Add the Content::Version or latest Content version.
  def << content
    return unless content
    content = content.versions.latest if Content === content
    raise ArgumentError, "Expected Content or Content::Version" unless Content::Version === content
    save! unless self.id
    revision_list_contents.create(:content_version => content)
    self
  end


  def size
    revision_list_contents.size
  end
end


