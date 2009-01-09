#
# Represents a name on a RevisionList.
#
#
class RevisionListName < ActiveRecord::Base
  acts_as_versioned

  belongs_to :revision_list

  validates_format_of :name, :with => /\A([a-z_][a-z0-9_]*)\Z/
  validates_uniqueness_of :name

end


