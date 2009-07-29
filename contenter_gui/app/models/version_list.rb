#
# Represents a list of content versions.
#
class VersionList < ActiveRecord::Base
  include UserTracking
  include ThreadVariable

  ##############################

  has_many :version_list_names, 
           :order => 'version_list_names.name'


  ##############################
  # Content

  # the content versions explicitly referred to by this VL
  has_many :version_list_contents,
           :order => 'content_key_id'

  # a view which includes all content versions (explicit or PIT)
  has_many :version_list_content_version_views

  # the association which pulls from the view (USE THIS!)
  has_many :content_versions,
           :through => :version_list_content_version_views,
           :order => Content.order_by


  ##############################
  # ContentKey

  # the content_key versions explicitly referred to by this VL
  has_many :version_list_content_keys,
           :order => 'content_key_version_id'

  has_many :version_list_content_key_version_views

  has_many :content_key_versions,
           :through => :version_list_content_key_version_views,
           :order => '(SELECT content_keys.code FROM content_keys WHERE content_keys.id = content_key_versions.content_key_id)'


  ##############################


  cattr_accessor_thread :current, :initialize => '[ ]'
  cattr_accessor_thread :track_changes, :initialize => 'true'

  # Tracks changes in the given VersionList during the given block.
  # rl can be a Proc that lazyly returns a VersionList.
  def self.track_changes_in rl = nil, opts = { }
    current_save = self.current
    current = current_save.dup
    current << rl
    self.current = current
    yield
  ensure
    self.current = current_save
  end


  # Registers content change with all current VersionLists.
  # Callback via VersionList::ChangeTracking.
  def self.content_changed! x
    return if track_changes == false
    self.current.map! do | rl |
      rl = rl.call if Proc === rl
      rl << x
      rl
    end
  end


  # Executes block in a transaction with version tracking.
  # Returns the new version list of all current content versions.
  # If exception is thrown, version list is aborted.
  # See Content::API for an example.
  # The new version list is returned.
  def self.after(opts = { })
    rl = nil
    VersionList.transaction do
      rl = self.new(opts) if opts
      yield
      rl.set_current_versions! if opts
    end
    rl
  end


  # Adds all current Content::Versions and ContentKey::Versions to this VersionList.
  def set_current_versions!
    self.class.transaction do
      save! unless self.id

      t = VersionListContent.table_name
 
      connection.execute <<"END"
DELETE FROM #{t} WHERE version_list_id = #{self.id}
END
      
      connection.execute <<"END"
INSERT INTO #{t} ( version_list_id, content_version_id )
SELECT #{self.id}, content_versions.id 
FROM contents, content_versions 
WHERE content_versions.content_id = contents.id AND content_versions.version = contents.version
END

      t = VersionListContentKey.table_name
      
      connection.execute <<"END"
DELETE FROM #{t} WHERE version_list_id = #{self.id}
END
      
      connection.execute <<"END"
INSERT INTO #{t} ( version_list_id, content_key_version_id )
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


  # Adds Content version to this VersionList.
  def add_content content
    return unless content
    self.transaction do
      content = content.versions.latest if Content === content
      raise ArgumentError, "Expected Content or Content::Version" unless Content::Version === content

      save! unless self.id

      # Dont add if it's already been added.
      return if content_versions.find(:first, :conditions => [ 'content_id = ?', content ])

      connection.
        execute("DELETE FROM version_list_contents 
               WHERE version_list_id = #{self.id}
                 AND content_version_id IN
                     (SELECT id FROM content_versions WHERE content_id = #{content.content.id})"
                )
      version_list_contents.create!(:content_version => content)

      # Invalidate association caches.
      version_list_contents.reset
      content_versions.reset
    end
    self
  end

  # Adds ContentKey version to this VersionList.
  def add_content_key content_key
    return unless content_key
    self.transaction do
      content_key = content_key.versions.latest if ContentKey === content_key
      raise ArgumentError, "Expected ContentKey or ContentKey::Version" unless ContentKey::Version === content_key

      save! unless self.id

      # Dont add if it's already been added.
      return if content_key_versions.find(:first, :conditions => [ 'content_key_id = ?', content_key ])

      connection.
        execute("DELETE FROM version_list_content_keys 
               WHERE version_list_id = #{self.id}
                 AND content_key_version_id IN
                     (SELECT id FROM content_key_versions WHERE content_key_id = #{content_key.content_key.id})"
              )
      version_list_content_keys.create!(:content_key_version => content_key)

      # Invalidate association caches.
      version_list_content_keys.reset
      content_key_versions.reset
    end
    self
  end


  # Returns the size of this VersionList.
  def size
    version_list_contents.size + version_list_content_keys.size
  end


  # Returns true if this VersionList is empty.
  def empty?
    size == 0
  end


  # Revert to previous versions if each version is current.
  def revert!
    track_changes_save = self.class.track_changes
    self.class.track_changes = false
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


