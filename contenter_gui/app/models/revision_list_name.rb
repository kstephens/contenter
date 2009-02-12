#
# Represents a name on a RevisionList.
#
#
class RevisionListName < ActiveRecord::Base
  include UserTracking

  # USE_VERSION = (RAILS_ENV != 'test') unless defined? USE_VERSION
  USE_VERSION = true unless defined? USE_VERSION
  if USE_VERSION
    acts_as_versioned
    set_locking_column :version
  end

  belongs_to :revision_list

  validates_format_of :name, :with => /\A([a-z_][a-z0-9_]*)\Z/
  validates_uniqueness_of :name

  before_validation :initialize_revision_list!
  def initialize_revision_list!
    self.revision_list_id ||= 1
  end

end


Content::Version.class_eval do
  def revision_list_names
    @revision_list_names ||=
      RevisionListName.find_by_sql <<"END"
SELECT DISTINCT
    revision_list_names.* 
FROM 
    revision_list_names,
    revision_lists,
    revision_list_contents,
    content_versions
WHERE 
    revision_list_names.revision_list_id      = revision_lists.id 
AND revision_lists.id                         = revision_list_contents.revision_list_id
AND revision_list_contents.content_version_id = content_versions.id
ORDER BY revision_list_names.name
END
  end
end


Content.class_eval do
  def revision_list_names
    last.revision_list_names
  end
end



