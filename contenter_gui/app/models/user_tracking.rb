
# Supplies User tracking behavior.
module UserTracking
  # Generic UserTracking error.
  class Error < ::Exception; end

  def self.default_user= user
    case user
    when User, nil
    when Proc
    when String
      user = User.find(:first, :conditions => { :login => user }) || 
        (raise ArgumentError, "cannot find user login=#{user}")
    else
      raise ArgumentError, "Expected User login String, User object or nil"
    end
    
    @@default_user = user
  end


  def self.default_user
    @@default_user ||= 
      User.find(:first, :conditions => { :login => 'root' }) || 
      (raise UserTracking, "cannot determine default user")
  end


  def self.current_user
    x = 
      Thread.current[:'UserTracking.current_user'] ||
      default_user
    x = x.call if Proc === x
    x
  end
  
  def self.current_user= user
    case user
    when User, nil
    when Proc
    when String
      user = User.find(:first, :conditions => { :login => user }) || (raise ArgumentError, "cannot find user login=#{user}")
    else
      raise ArgumentError, "Expected User login String, User object or nil"
    end
    
    Thread.current[:'UserTracking.current_user'] = user
  end
 
  # Stuff directives into including module
  def self.included(recipient)
    recipient.extend(ModelClassMethods)
    recipient.class_eval do
      include ModelInstanceMethods
      
      belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_user_id'
      belongs_to :updater, :class_name => 'User', :foreign_key => 'updater_user_id'

      validates_presence_of :creator_user_id

      before_validation_on_create :create_user_tracking!

      before_validation :update_user_tracking!
    end
  end # #included directives
  
  
  #
  # Class Methods
  #
  module ModelClassMethods
    def add_user_tracking_columns
      
    end
  end # class methods
  
  #
  # Instance Methods
  #
  module ModelInstanceMethods
    
    def create_user_tracking!
      self.creator ||= 
        UserTracking.current_user || 
        (raise UserTracking::Error, "current user is not defined")
    end

    def update_user_tracking!
      unless self.new_record?
        self.updater = 
          UserTracking.current_user || 
          (raise UserTracking::Error, "current user is not defined")
      end
    end
    
  end # instance methods
  
end
