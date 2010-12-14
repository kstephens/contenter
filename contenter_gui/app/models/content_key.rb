
#
# Represents unique content key for a particular ContentType.
#
# The ContentKey#code format is validated against the ContentType#code_regexp.
# This forces all content keys of a given type to use the same format.
#  
class ContentKey < ActiveRecord::Base
  include ContentKeyBehavior

  # generates ContentKey::Version
  acts_as_versioned :association_options => { :dependent => :destroy }
  
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

  has_many :version_list_content_keys,
           :foreign_key => :content_key_version_id,
           :dependent => :destroy

  def is_current_version?
    content_key.version == self.version
  end

end

require 'content_key_version'

