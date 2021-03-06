require 'digest/sha1'

class User < ActiveRecord::Base
  include Garm::AuthorizationCache::Methods
  include UserCapabilityMethods

  # Lookup a User by id or login.
  # Returns nil if User cannot be found.
  def self.[](x)
    Garm::AuthorizationCache.current.user(x)
  end

  has_many :role_users, :order => 'role_id'
  has_many :roles, :through => :role_users, :order => 'sequence, role_id', 
  # :source => :user,
    :extend => Garm::AuthorizationCache::Methods::HasMany 
  
  # has_role? simply needs to return true or false whether a user has a role or not.  
  # It may be a good idea to have "admin" roles return true always
  def has_role?(role_in_question)
    @_list ||= self.roles.collect(&:name)
    return true if @_list.include?("admin") # <= THIS IS BULLSHIT.
    (@_list.include?(role_in_question.to_s) )
  end
  # ---------------------------------------
  
   
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken

  validates_presence_of     :login
  validates_length_of       :login,    :within => 3..40
  validates_uniqueness_of   :login
  validates_format_of       :login,    :with => Authentication.login_regex, :message => Authentication.bad_login_message

  validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name,     :maximum => 100

  validates_presence_of     :email
  validates_length_of       :email,    :within => 6..100 #r@a.wk
  validates_uniqueness_of   :email
  validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message

  

  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :name, :password, :password_confirmation



  # Authenticates a user by their login name and unencrypted password.  Returns the User or nil.
  #
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_by_login(login) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

=begin
  # WTF: why wouldn't you want logins to be case sensitive?
  def login=(value)
    write_attribute :login, (value && value.downcase)
  end
=end

  def email=(value)
    write_attribute :email, (value && value.downcase)
  end


  def to_s
    login
  end


  protected
end
