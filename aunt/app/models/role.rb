
# Roles are collections of Capabilities assigned to
# Users.   Users can have many Roles, each Role
# has Capabilities that allow or deny actions.
# 
# To add Roles to a User:
#
#   User['joeuser'].roles << Role['superuser']
#
# To build the Capabilities of a Role use the following:
#
#   Role.build_role_capability [ 'foo_role', [ 'controller/foo/action' ] ]
#
class Role < ActiveRecord::Base
  include CapabilityHelper
  include AuthCacheMethods

  has_many :role_capabilities

  has_many :capabilities, :through => :role_capabilities # Includes capabilities that are expressly not allowed.
  has_many :allowed_capabilities, :through => :role_capabilities, :source => :capability, :conditions => 'role_capabilities.allow'
  has_many :denied_capabilities, :through => :role_capabilities, :source => :capability, :conditions => 'NOT role_capabilities.allow'

  has_and_belongs_to_many :users, :extend => AuthCacheMethods::HasMany

  validates_format_of :name, :with => /\A([a-z0-9_])+\Z/i
  validates_presence_of :name
  validates_presence_of :description


  def to_s
    name
  end

  # Lookup a Role by id or name.
  def self.[](x)
    AuthorizationCache.current.role(x)
  end


  auth_cache_delegate :has_capability?
  # Returns true if this Role allows the Capability.
  # Returns false if this Role does not allow the Capability.
  # Returns nil if its inconclusive.
  # Uncached version.
  def _has_capability? cap
    # Try immediate capabilities.
    caps = capability_expand(cap)
    caps.each do | cap |
      # $stderr.puts "  Role[#{name}].capability[#{cap.inspect}]"
      allow = capability[cap]
      return allow unless allow.nil?
    end

    # Inconclusive.
    nil
  end


=begin

  alias :__has_capability? :_has_capability?

  def _has_capability?(capability)
    result = __has_capability?(capability)
    $stderr.puts "  Role[#{self.name.inspect}]._has_capability?(#{capability.inspect}) => #{result.inspect}"
    result
  end
=end


  auth_cache_delegate :capability

  # Returns a Hash of Capability name to allowance.
  def _capability
    role_capabilities.inject({ }) do | h, rc |
      h[rc.capability.name.dup.freeze] = rc.allow
      h
    end.freeze
  end


  ####################################################################
  # Data helpers
  #
  

  # See db/*_create_default_roles.rb and and Aunt::Seeder as an example.
  def self.build_role_capability *role_capability
    extend Aunt::Wildcard

    Role.transaction do 
      role_capability.each do | (role_name, desc, caps) |
        role = role_name
        begin
          # $stderr.puts "  Role: #{role.inspect}"
          role = 
            Role.find(:first, :conditions => { :name => role }) || 
            Role.create!(:name => role, :description => desc || role)
          role.update_attribute(:description, desc) if role.description.blank? && ! desc.blank?
        rescue Exception => err
          raise ArgumentError, "Role #{role_name.inspect} : #{err.inspect}" 
        end

        if Array === caps
          caps = caps.inject({ }) { | h, cap | h[cap] = true; h }
        end
        caps.each do | cap, allow |
          brace_expansion(cap).uniq.each do | cap |
            cap_name = cap
            begin
              # $stderr.puts "    Capability: #{cap.inspect} => #{allow.inspect}"
              cap = 
                Capability.find(:first, :conditions => { :name => cap } ) || 
                Capability.create!(:name => cap, :description => cap)

              if role_cap = RoleCapability.find(:first, :conditions => { :role_id => role.id, :capability_id => cap.id })
                role_cap.allow = allow
                role_cap.save!
              else
                role_cap = RoleCapability.create!(:role => role, :capability => cap, :allow => allow)
              end
            rescue Exception => err
              raise ArgumentError, "Capability #{cap_name.inspect} : #{err.inspect}" 
            end
          end
        end
      end
    end
  end


  # See db/*_create_default_roles.rb and Contenter::Seeder as an example.
  def self.build_user_role user, *roles
    User.transaction do
      unless User === user
        user = User.find(:first, :conditions => { :login => user }) || 
          (raise ArgumentError, "Cannot find User #{user.inspect}")
      end
      roles.each do | role |
        role_name = role
        begin
          role = 
            Role.find(:first, :conditions => { :name => role_name }) || 
            Role.create!(:name => role_name, :description => role_name)
          # $stderr.puts "    User[#{user.login.inspect}].roles = #{user.roles.map{|x| x.name}.inspect}"
          unless user.roles.include?(role)
            $stderr.puts "      + User[#{user.login.inspect}].roles << #{role.name.inspect}"
            user.roles << role 
          end
        rescue Exception => err
          $stderr.puts "#{err.backtrace * "\n"}"
          raise ArgumentError, "Role #{role_name.inspect}: #{err.inspect}" 
        end
      end
    end
  end


end # class


