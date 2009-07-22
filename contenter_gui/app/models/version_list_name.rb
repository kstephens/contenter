#
# Represents a name on a VersionList.
#
#
class VersionListName < ActiveRecord::Base
  include UserTracking

  # USE_VERSION = (RAILS_ENV != 'test') unless defined? USE_VERSION
  USE_VERSION = true unless defined? USE_VERSION
  if USE_VERSION
    acts_as_versioned
    set_locking_column :version
  end

  belongs_to :version_list

  validates_format_of :name, :with => /\A([a-z_][a-z0-9_]*)\Z/
  validates_uniqueness_of :name

  before_validation :initialize_version_list!
  def initialize_version_list!
    self.version_list_id ||= 1
  end

end

# similar to reopening class Content::Version, but lets autoloader load it
Content::Version.class_eval do
  def version_list_names
    @version_list_names ||=
      VersionListName.find_by_sql <<"END"
SELECT DISTINCT
    version_list_names.* 
FROM 
    version_list_names,
    version_lists,
    version_list_contents,
    content_versions
WHERE 
    version_list_names.version_list_id      = version_lists.id 
AND version_lists.id                         = version_list_contents.version_list_id
AND version_list_contents.content_version_id = #{self.id}
ORDER BY 
    version_list_names.name
END
  end
end


Content.class_eval do
  def version_list_names
    last.version_list_names
  end
end



