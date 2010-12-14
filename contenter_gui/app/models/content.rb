require 'contenter/error'

#
# Represents the content for a particular:
#
#   content_key
#   language
#   country
#   brand
#   application
#   mime_type
#
# Actual content is stored in Content#data.
#
class Content < ActiveRecord::Base
  include ContentBehavior

  ###############################################

  # Generates Content::Version.
  # Foreign key columns and data, trigger versioning, specifically NOT content_status_id !!
  acts_as_versioned :if_changed => CHANGE_COLUMNS,
                    :association_options => { :dependent => :destroy } 

  validates_uniqueness_of :uuid

# This should work according to rails documentation.
# But it doesn't generate the correct error message.  
=begin
  validates_uniqueness_of :content_key, 
    :scope => BELONGS_TO_ID
=end
  

  ###############################################
  # ContentStatus support
  #
  
  # NOTES: When we start using red_steak, these methods will rely introspection on the statemachine.

  def self.status_actions
    @@status_actions ||= [ :approve, :release ].freeze
  end

  def self.conditions_for_status_action action
    x = @@conditions_for_status_action ||= {
      :approve =>
      "content_status_id NOT IN ( #{[ :approved, :released ].map{|x| ContentStatus[x].id } * ', '} )",
      :release =>
      "content_status_id IN (     #{[ :approved            ].map{|x| ContentStatus[x].id } * ', '} )"
    }
    x[action] or raise Contenter::Error::InvalidInput, "Invalid status_action #{action.inspect}"
  end

  def allowed_status_actions
    self.class.status_actions.select { | x | can_do_status_action? x }
  end

  def can_do_status_action? action
    case action
      # approve anything that is not already approved or released.
    when :approve
      ! [ 'approved', 'released' ].include?(content_status.code) 

      # release anything that is approved.
    when :release
      [ 'approved' ].include?(content_status.code) 
    when
      false
    end
  end

  def do_status_action! action
    raise Contenter::Error::InvalidInput, "Cannot do action #{action}" unless can_do_status_action? action
    case action
    when :approve
      set_content_status! :approved
    when :release
      set_content_status! :released
    end
    self
  end
  

  ####################################################################
  # ContentConversion support.
  #

  # Causes @content_changed to be true, if content actually changed.
  before_save :check_content_changed!
  def check_content_changed!
    content_changed?
    @invalidate_content_conversions = @content_changed
    true
  end

  after_save :invalidate_content_conversions!
  # If content changed, invalidate ContentConversion.
  def invalidate_content_conversions!
    if @invalidate_content_conversions
      @invalidate_content_conversions = false
      # $stderr.puts "Invalidating ContentConversions for :src_uuid => #{self.uuid.inspect}"
      ContentConversion.invalidate_src!(:src_uuid => self.uuid)
    end
  end

end # class


Content::Version.class_eval do
  include ContentBehavior
  include VersionList::ChangeTracking

  has_many :version_list_content_version_views, 
           :foreign_key => :content_version_id

  has_many :version_lists,
           :through => :version_list_content_version_views

  has_many :version_list_contents,
           :foreign_key => :content_version_id,
           :dependent => :destroy

  def is_current_version?
    content.version == self.version
  end

end # class

require 'content_version'

require 'active_record_defer_constraints'
