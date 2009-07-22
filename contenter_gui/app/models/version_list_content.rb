#
# Represents the association between
# a VersionList and Content.
#
class VersionListContent < ActiveRecord::Base

  belongs_to :version_list
  belongs_to :content_version, :class_name => 'Content::Version'

  validates_presence_of :version_list_id
  validates_presence_of :content_version_id

end


