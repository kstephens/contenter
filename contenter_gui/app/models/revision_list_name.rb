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

end


