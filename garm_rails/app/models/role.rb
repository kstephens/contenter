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
  include Garm::CapabilityExpand
  include Garm::AuthorizationCache::Methods

  has_many :role_inheritances,
    :foreign_key => 'child_role_id'

  has_many :child_roles, 
    :class_name => 'Role',
    :extend => Garm::AuthorizationCache::Methods::HasMany,
=begin
# THIS IS SUFFICIENTLY BROKEN IN RAILS 2.2.2
# Always generates:
#  WHERE (("role_inheritances".role_id = roles.id))
    :through => :role_inheritances, :order => 'role_inheritiances.child_role_id', 
    :foreign_key => 'parent_role_id'
=end
    :finder_sql => <<'END'
SELECT "roles".* FROM "roles"  
  INNER JOIN role_inheritances ON roles.id = role_inheritances.child_role_id
  WHERE (("role_inheritances".parent_role_id = #{id})) 
  ORDER BY roles.name
END

  has_many :parent_roles,
    :class_name => 'Role',
    :extend => Garm::AuthorizationCache::Methods::HasMany,
=begin
# THIS IS SUFFICIENTLY BROKEN IN RAILS 2.2.2
# Always generates:
#  WHERE (("role_inheritances".role_id = roles.id))
    :through => :role_inheritances, :order => 'role_inheritances.sequence, role_inheritances.parent_role_id', 
    :class_name => 'Role', :foreign_key => 'child_role_id',
=end
    :finder_sql => <<'END'
SELECT "roles".* FROM "roles"
  INNER JOIN role_inheritances ON roles.id = role_inheritances.parent_role_id
  WHERE (("role_inheritances".child_role_id = #{id}))
  ORDER BY role_inheritances.sequence, roles.name}
END

  has_many :role_capabilities

  has_many :capabilities, :through => :role_capabilities # Includes capabilities that are expressly not allowed.
  has_many :allowed_capabilities, :through => :role_capabilities, :source => :capability, :conditions => 'role_capabilities.allow'
  has_many :denied_capabilities,  :through => :role_capabilities, :source => :capability, :conditions => 'NOT role_capabilities.allow'

  has_many :role_users, :order => 'user_id'
  has_many :users, :through => :role_users, :order => 'users.login', 
    :extend => Garm::AuthorizationCache::Methods::HasMany

  validates_format_of :name, :with => /\A([a-z0-9_])+\Z/i
  validates_presence_of :name
  validates_presence_of :description

  def to_s
    name
  end

  # Lookup a Role by id or name.
  def self.[](x)
    Garm::AuthorizationCache.current.role(x)
  end

  auth_cache_delegate :has_capability?
  auth_cache_delegate :capability

  def inherit_from_role! *parent_roles
    parent_roles.each do | parent_roles |
      RoleInheritance.build(:child_role => self, :parent_role => parent_role)
    end
    self
  end

  ####################################################################
  # Data helpers
  #
  

  # See db/*_create_default_roles.rb and and Garm::Seeder as an example.
  def self.build_role_capability *role_capability
    extend Garm::Wildcard

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
          # $stderr.puts "      ? User[#{user.login.inspect}].roles << Role[#{role.name.inspect}]"
          unless user.roles.include?(role)
            $stderr.puts "      + User[#{user.login.inspect}].roles << Role[#{role.name.inspect}]"
            RoleUser.create!(:user => user, :role => role)
            user.roles.reload
            role.users.reload
          end
        rescue Exception => err
          $stderr.puts "#{err.backtrace * "\n"}"
          raise ArgumentError, "Role #{role_name.inspect}: #{err.inspect}" 
        end
      end
    end
  end


end # class
