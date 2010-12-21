require 'garm/to_id'

# Supplies User tracking behavior.
module UserTracking
  # Generic UserTracking error.
  class Error < ::Exception; end

  
  @@default_user ||= nil

  # Sets the process' default User.
  # Can be User or Proc or String.
  def self.default_user= user
    if User.count == 0
      case user
      when User, nil, Proc, String, Symbol, Integer
      else
        raise ArgumentError, "Expected User login String, User object, Proc, Integer, or nil"
      end
    else
      case user
      when User, nil, Proc, String
      else
        user = coerce_user(user) || (raise ArgumentError, "Cannot find User login=#{user}")
      end
    end 
    
    @@default_user = user
  end


  def self.coerce_user x
    x = x.call if Proc === x
    case x
    when String, Symbol
      x = User[x.to_s] 
    when Integer
      x = User[x]
    end
    x
  end

  def self.default_user
    x = coerce_user(@@default_user ||= 'root')
  end

  def self.with_default_user x
    save_default_user = @@default_user
    self.default_user = x
    yield
  ensure
    @@default = save_default_user
  end

  [ :current, :real ].each do | name |
    expr = [ <<'END'.gsub(/<<NAME>>/, name.to_s), __FILE__, __LINE__ ]
  # Returns the <<NAME>> Thread's User.
  def self.<<NAME>>_user
    x = coerce_user(
                    Thread.current[:'UserTracking.<<NAME>>_user'] ||
                    default_user
                    )
    x
  end
  

  # Sets the <<NAME>> Thread's User.
  # May be a Proc, String or User object.
  def self.<<NAME>>_user= user
    case user
    when User, nil, Proc, String, Integer
    else
      user = coerce_user(user) || (raise ArgumentError, "cannot find user login=#{user}")
    end
    
    Thread.current[:'UserTracking.<<NAME>>_user'] = user
  end
 

  def self.with_<<NAME>>_user user
    save = Thread.current[:'UserTracking.<<NAME>>_user']
    self.<<NAME>>_user = user
    yield
  ensure
    Thread.current[:'UserTracking.<<NAME>>_user'] = save
  end

END
  # $stderr.puts "expr = ----\n#{expr}"
  class_eval(*expr)
end

  @@user_tracking ||= nil

  def self.user_tracking
    @@user_tracking
  end

  def self.with_user_tracking mode = true
    _user_tracking = @@user_tracking
    @@user_tracking = mode
    yield
  ensure
    @@user_tracking = _user_tracking
  end


  # Adds creator, updater relationships to including class.
  def self.included(recipient)
    recipient.extend(ModelClassMethods)
    recipient.class_eval do
      include ModelInstanceMethods
      
      [ :creator, :updater ].each do | x |
        belongs_to x, :class_name => 'User', :foreign_key => "#{x}_user_id", :extend => ModelCache::BelongsTo
        validates_presence_of :"#{x}_user_id"
      end
      before_validation_on_create :create_user_tracking!

      before_validation :update_user_tracking!
    end
  end # #included directives
  
  
  # Adds supporting columns to a migration table.
  def self.add_columns t
    t.column :creator_user_id, :integer,
    :null => false, :references => :users
    t.column :updater_user_id, :integer,
    :null => false, :references => :users
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
    # Disable creator and updater tracking during block.
    def without_user_tracking(disable = true)
      without_user_tracking_save = @without_user_tracking
      raise ArgumentError, "block not given" unless block_given?
      @without_user_tracking = disable
      yield
    ensure
      @without_user_tracking = without_user_tracking_save
    end

    # Defaults object creator to the current user.
    def create_user_tracking!
      return if @without_user_tracking
      self.creator ||= 
        UserTracking.current_user || 
        (raise UserTracking::Error, "current_user is not defined")
    end

    # Sets object updater to the current user.
    def update_user_tracking!
      return if @without_user_tracking
      self.updater = 
        UserTracking.current_user || 
        (raise UserTracking::Error, "current_user is not defined")
    end
    
  end # instance methods
  
end
