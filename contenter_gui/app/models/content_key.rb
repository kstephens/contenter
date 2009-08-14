
#
# Represents unique content key for a particular ContentType.
#
# The ContentKey#code format is validated against the ContentType#code_regexp.
# This forces all content keys of a given type to use the same format.
#  
class ContentKey < ActiveRecord::Base
  include ContentKeyBehavior

  acts_as_versioned # generates ContentKey::Version
  set_locking_column :version
  
  ####################################################################

  validates_uniqueness_of :code, :scope => BELONGS_TO_ID
  validates_uniqueness_of :uuid

  validate :validate_code_with_content_type!
end


ContentKey::Version.class_eval do
  include ContentKeyBehavior
  include VersionList::ChangeTracking

  has_many :version_list_content_key_version_views,
           :foreign_key => :content_key_version_id 

  has_many :version_lists,
           :through => :version_list_content_key_version_views

  def is_current_version?
    content_key.version == self.version
  end

end

require 'content_key_version'

