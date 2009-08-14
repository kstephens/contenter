#
# Represents the content for a particular:
#
#   content_key
#   language
#   country
#   brand
#   application
#   mime_type
#
# Actual content is stored in Content#data.
#
class Content < ActiveRecord::Base
  include ContentBehavior

  # Base Content::Error class.
  class Error < ::Exception
    # Raised when an object cannot be found.
    class NotFound < self; end
    # Raised when an edit is attempted on a version that is older.
    class Conflict < self; end
    # Raised when an edit is attempted on a based on an ambiguous lookup.
    class Ambiguous < self; end
  end

  ###############################################

  # generate Content::Version.
  acts_as_versioned

  set_locking_column :version

  validates_uniqueness_of :uuid
  
=begin
  validates_uniqueness_of :content_key, 
    :scope => BELONGS_TO_ID
=end

end


Content::Version.class_eval do
  include ContentBehavior
  include VersionList::ChangeTracking

  has_many :version_list_content_version_views, 
           :foreign_key => :content_version_id

  has_many :version_lists,
           :through => :version_list_content_version_views


  def is_current_version?
    content.version == self.version
  end

end # class


require 'content_version'

