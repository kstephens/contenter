
# Supplies User tracking behavior.
module UserTracking
  # Generic UserTracking error.
  class Error < ::Exception; end

  # Sets the process' default User.
  # Can be User or Proc or String.
  def self.default_user= user
    case user
    when User, nil, Proc
    when String
      user = User[user] || 
        (raise ArgumentError, "Cannot find User login=#{user}")
    else
      raise ArgumentError, "Expected User login String, User object, Proc or nil"
    end
    
    @@default_user = user
  end


  def self.default_user
    x = @@default_user ||= 'root' 
    x = x.call if Proc === x
    x = User[x] if String === x
    x
  end


  # Returns the current Thread's User.
  def self.current_user
    x = 
      Thread.current[:'UserTracking.current_user'] ||
      default_user
    x = x.call if Proc === x
    x
  end
  

  # Sets the current Thread's User.
  # May be a Proc, String or User object.
  def self.current_user= user
    case user
    when User, nil, Proc
    when String
      user = User[user] || (raise ArgumentError, "cannot find user login=#{user}")
    else
      raise ArgumentError, "Expected User login String, User object or nil"
    end
    
    Thread.current[:'UserTracking.current_user'] = user
  end
 

  def self.with_current_user user
    save = Thread.current[:'UserTracking.current_user']
    self.current_user = user
    yield
  ensure
    Thread.current[:'UserTracking.current_user'] = save
  end


  # Adds creator, updater relationships to including class.
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
  
  
  # Adds supporting columns to a migration table.
  def self.add_columns t
    t.column :creator_user_id, :integer,
    :null => false, :references => :users
    t.column :updater_user_id, :integer,
    :null => true, :references => :users
    t.timestamps
  end


  #
  # Class Methods
  #
  module ModelClassMethods
  end # class methods
  

  #
  # Instance Methods
  #
  module ModelInstanceMethods
    # Defaults object creator to the current user.
    def create_user_tracking!
      self.creator ||= 
        UserTracking.current_user || 
        (raise UserTracking::Error, "current user is not defined")
    end

    # Sets object updater to the current user.
    def update_user_tracking!
      unless self.new_record?
        self.updater = 
          UserTracking.current_user || 
          (raise UserTracking::Error, "current user is not defined")
      end
    end
    
  end # instance methods
  
end
