class VersionList
# Supplies VersionList content change tracking behavior.
module ChangeTracking
  # Generic ChangeTracking error.
  class Error < ::Exception; end

  # Adds change tracking support
  def self.included(base)
    super
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
        after_save   :track_change_in_version_lists!
        after_create :track_change_in_version_lists!
    end
  end # #included directives
  
  #
  # Class Methods
  #
  module ModelClassMethods
  end # class methods
  

  #
  # Instance Methods
  #
  module ModelInstanceMethods
    # Notifies all active VersionLists in the current Thread that
    # this acts_as_versioned Version object was saved.
    def track_change_in_version_lists!
      VersionList.content_changed! self
    end
  end

end # module
end # class
