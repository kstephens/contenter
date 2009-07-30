#
# Represents the association between
# a VersionList and ContentKey::Version through
# the version_list_content_key_version_view view.
#
# The view is read-only.
class VersionListContentKeyVersionView < ActiveRecord::Base
  set_table_name 'version_list_content_key_version_view'

  belongs_to :version_list
  belongs_to :content_key_version, :class_name => 'ContentKey::Version'

end


