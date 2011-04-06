#
# Represents a name on a VersionList.
#
#
class VersionListName < ActiveRecord::Base
  include UserTracking
  include AuxDataModel

  acts_as_versioned
  set_locking_column :version

  belongs_to :version_list

  validates_format_of :name, :with => /\A([a-z_][a-z0-9_]*)\Z/
  validates_uniqueness_of :name

  before_validation :initialize_version_list!
  def initialize_version_list!
    self.version_list_id ||= 1
  end

  def self.by_model_sql model, model_id
<<"END"
SELECT DISTINCT
    vln.* 
FROM 
     version_list_names vln
JOIN version_lists vl                           ON vl.id = vln.version_list_id
JOIN version_list_#{model}_version_view vlcv    ON vlcv.version_list_id = vl.id
WHERE 
    vlcv.#{model}_version_id = #{model_id}
ORDER BY 
    vln.name
END
  end
end


VersionListName::Version.class_eval do
  include AuxDataModel
end


# Get the version_list_names for most recent version of Content or ContentKey.
[ Content, ContentKey ].each do | cls |
  cls.class_eval do
    def version_list_names
      last.version_list_names
    end
  end
end


Content::Version.class_eval do
  def version_list_names
    @version_list_names ||=
      VersionListName.find_by_sql(VersionListName.by_model_sql(:content, self.id))
  end
end


ContentKey::Version.class_eval do
  def version_list_names
    @version_list_names ||=
      VersionListName.find_by_sql(VersionListName.by_model_sql(:content_key, self.id))
  end
end




