#
# Represents a list of content revisions.
#
#
class RevisionList < ActiveRecord::Base

  #has_many_through :content

  def add_revisions!
    save! unless self.id
    t = :revision_list_contents
    connection.execute("DELETE FROM #{t} WHERE revision_list_id = #{self.id}")
    connection.execute("INSERT INTO #{t} ( revision_list_id, content_id, content_version ) SELECT #{self.id}, contents.id, 1 FROM contents");
    self
  end

end


