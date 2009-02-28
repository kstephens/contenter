#
# Represents a list of content revisions.
#
class RevisionList < ActiveRecord::Base
  include UserTracking
  include ThreadVariable

  has_many :revision_list_names, 
           :order => 'revision_list_names.name'

  has_many :revision_list_contents, 
           :order => 'content_version_id'
  has_many :content_versions,
           :through => :revision_list_contents,
           :order => Content.order_by

  has_many :revision_list_content_keys,
           :order => 'content_key_version_id'
  has_many :content_key_versions, 
           :through => :revision_list_content_keys,
           :order => '(SELECT content_keys.code FROM content_keys WHERE content_keys.id = content_key_versions.content_key_id)'

  cattr_accessor_thread :current, :initialize => '[ ]'
  cattr_accessor_thread :track_changes, :initialize => 'true'

  # Tracks changes in the given RevisionList during the given block.
  # rl can be a Proc that lazyly returns a RevisionList.
  def self.track_changes_in rl = nil, opts = { }
    current_save = self.current
    current = current_save.dup
    current << rl
    self.current = current
    yield
  ensure
    self.current = current_save
  end


  # Registers content change with all current RevisionLists.
  # Callback via RevisionList::ChangeTracking.
  def self.content_changed! x
    return if track_changes == false
    self.current.map! do | rl |
      rl = rl.call if Proc === rl
      rl << x
      rl
    end
  end


  # Executes block in a transaction with revision tracking.
  # Returns the new revision list of all current content revisions.
  # If exception is thrown, revision list is aborted.
  # See Content::API for an example.
  # The new revision list is returned.
  def self.after(opts = { })
    rl = nil
    RevisionList.transaction do
      rl = self.new(opts) if opts
      yield
      rl.set_current_revisions! if opts
    end
    rl
  end


  # Adds all current Content::Versions and ContentKey::Versions to this RevisionList.
  def set_current_revisions!
    self.class.transaction do
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

      t = RevisionListContentKey.table_name
      
      connection.execute <<"END"
DELETE FROM #{t} WHERE revision_list_id = #{self.id}
END
      
      connection.execute <<"END"
INSERT INTO #{t} ( revision_list_id, content_key_version_id )
SELECT #{self.id}, content_key_versions.id 
FROM content_keys, content_key_versions 
WHERE content_key_versions.content_key_id = content_keys.id AND content_key_versions.version = content_keys.version
END

    end

    # Association caches are out-of-date.
    reload

    self
  end


  # Add the Content::Version or latest Content version,
  # or ContentKey::Version or latest ContentKey version.
  def << x
    # $stderr.puts "  #{self.object_id} << #{x.class} #{x.id}"
    case x
    when Content, Content::Version
      add_content x
    when ContentKey, ContentKey::Version
      add_content_key x
    else
      raise ArgumentError, "expected Content or ContentKey"
    end
    self
  end


  # Adds Content revision to this RevisionList.
  def add_content content
    return unless content
    self.transaction do
      content = content.versions.latest if Content === content
      raise ArgumentError, "Expected Content or Content::Version" unless Content::Version === content
      save! unless self.id
      # Dont add if it's already been added.
      return if content_versions.find(:first, :conditions => [ 'content_id = ?', content ])
      connection.
        execute("DELETE FROM revision_list_contents 
               WHERE revision_list_id = #{self.id}
                 AND content_version_id IN
                     (SELECT id FROM content_versions WHERE content_id = #{content.content.id})"
                )
      revision_list_contents.create!(:content_version => content)
      content_versions.reload
    end
    self
  end

  # Adds ContentKey revision to this RevisionList.
  def add_content_key content_key
    return unless content_key
    self.transaction do
      content_key = content_key.versions.latest if ContentKey === content_key
      raise ArgumentError, "Expected ContentKey or ContentKey::Version" unless ContentKey::Version === content_key
      save! unless self.id
      # Dont add if it's already been added.
      return if content_key_versions.find(:first, :conditions => [ 'content_key_id = ?', content_key ])
      connection.kstep
        execute("DELETE FROM revision_list_content_keys 
               WHERE revision_list_id = #{self.id}
                 AND content_key_version_id IN
                     (SELECT id FROM content_key_versions WHERE content_key_id = #{content_key.content_key.id})"
              )
      revision_list_content_keys.create!(:content_key_version => content_key)
      content_key_versions.reload
    end
    self
  end


  # Returns the size of this RevisionList.
  def size
    revision_list_contents.size + revision_list_content_keys.size
  end


  # Returns true if this RevisionList is empty.
  def empty?
    size == 0
  end


  # Revert to previous versions if each version is current.
  def revert!
    track_changes_save = self.class.track_changes_save
    self.class.track_changes_save = false
    self.transaction do
      content_versions.each do | c |
        if c.content.version == c.version
          c.content.revert_to(c)
        end
      end
      content_key_versions.each do | c |
        if c.content_key.version == c.version
          c.content_key.revert_to(c)
        end
      end
    end
  ensure 
    self.class.track_changes = track_changes_save
  end
end


