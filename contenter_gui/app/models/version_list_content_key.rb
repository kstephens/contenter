#
# Represents the association between
# a VersionList and ContentKey.
#
class VersionListContentKey < ActiveRecord::Base

  belongs_to :version_list
  belongs_to :content_key_version, :class_name => 'ContentKey::Version'

  validates_presence_of :version_list_id
  validates_presence_of :content_key_version_id

end


