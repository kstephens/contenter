#
# Represents the association between
# a VersionList and Content::Version through
# the version_list_content_version_view view.
#
# The view is read-only.
class VersionListContentVersionView < ActiveRecord::Base
  set_table_name 'version_list_content_version_view'

  belongs_to :version_list
  belongs_to :content_version, :class_name => 'Content::Version'

end


