require 'thread_variable'

class VersionList
# Supplies VersionList content change tracking behavior for ::Version models
# created by acts_as_versioned.
module ChangeTracking
  include ThreadVariable

  cattr_accessor_thread :debug, :initialize => 'false'

  # Generic ChangeTracking error.
  class Error < ::Exception; end

  # Adds change tracking support
  def self.included(base)
    super
    base.extend(ClassMethods)
    base.class_eval do
      include InstanceMethods

      after_save   :track_change_in_version_lists!
      after_create :track_change_in_version_lists!
    end
  end # #included directives
  
  #
  # Class Methods
  #
  module ClassMethods
  end # class methods
  

  #
  # Instance Methods
  #
  module InstanceMethods
    # Notifies all active VersionLists in the current Thread that
    # this acts_as_versioned Version object was saved.
    def track_change_in_version_lists!
      $stderr.puts "   #{self.class.name} #{self.id} track_change_in_version_lists!" if ChangeTracking.debug
      VersionList.content_changed! self
    end
  end

end # module
end # class
