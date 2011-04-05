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
    :foreign_key => 'child_role_id' do

    def reload
      @ancestors = @decendents = nil
      super
    end

    def ancestors clear = nil
      return @ancestors = nil if clear
      return @ancestors if @ancestors
      @ancestors = [ ]
      queue = [ @owner ]
      while role = queue.shift
        unless @ancestors.include?(role)
          @ancestors << role
          queue.push *role.parent_roles
        end
      end
      @ancestors
    end
    alias :parent_roles_deep :ancestors

    def decendents clear = nil
      return @decendents = nil if clear
      return @decendents if @decendents
      @decendents = [ ]
      queue = [ @owner ]
      while role = queue.shift
        unless @decendents.include?(role)
          @decendents << role
          queue.push *role.child_roles
        end
      end
      @decendents
    end
    alias :child_roles_deep :decendents
  end

  has_many :child_roles, 
    :class_name => 'Role',
=begin
# Since has_many :through is broken we have to create our own #push, #delete etc, methods.
# THIS IS SUFFICIENTLY BROKEN IN RAILS 2.2.2
# Always generates:
#  WHERE (("role_inheritances".role_id = roles.id))
    :through => :role_inheritances, :order => 'role_inheritiances.child_role_id', 
    :foreign_key => 'parent_role_id'
=end
    :finder_sql => <<'END',
SELECT "roles".* FROM "roles"  
  INNER JOIN role_inheritances ON roles.id = role_inheritances.child_role_id
  WHERE (("role_inheritances".parent_role_id = #{id})) 
  ORDER BY roles.name
END
    :extend => Garm::AuthorizationCache::Methods::HasMany do
    def push *roles
      @owner.save! if @owner.new_record?
      roles.flatten!
      roles.uniq!
      roles.map! { | r | Role[r] }
      roles.each do | role |
        RoleInheritance.create!(:child_role => role, :parent_role => @owner)
      end
      self
    end
    alias :<< :push

    def delete *roles
      return self if @owner.new_record?
      roles.flatten!
      roles.uniq!
      roles.map! { | r | Role[r] }
      RoleInheritance.destroy_all([ 'parent_role_id = ? AND child_role_id IN (?)', @owner, roles ])
      [ @owner, *roles ].each do | role |
        role.invalidate_role_inheritances!
      end
      self
    end

    def set! roles
      roles.map! { | r | Role[r] }
      current = @owner.new_record? ? [ ] : to_a
      del = current - roles
      add = roles - current
      delete *del
      push *add
      self
    end
  end
  def child_role_ids= roles
    roles.map! { | r | String === r ? r.to_i : r }
    child_roles.set! roles
    self
  end

  def child_roles_deep
    role_inheritances.child_roles_deep
  end

  has_many :parent_roles,
    :class_name => 'Role',
=begin
# Since has_many :through is broken we have to create our own #push, #delete etc, methods.
# THIS IS SUFFICIENTLY BROKEN IN RAILS 2.2.2
# Always generates:
#  WHERE (("role_inheritances".role_id = roles.id))
    :through => :role_inheritances, :order => 'role_inheritances.sequence, role_inheritances.parent_role_id', 
    :class_name => 'Role', :foreign_key => 'child_role_id',
=end
    :finder_sql => <<'END',
SELECT "roles".* FROM "roles"
  INNER JOIN role_inheritances ON roles.id = role_inheritances.parent_role_id
  WHERE (("role_inheritances".child_role_id = #{id}))
  ORDER BY role_inheritances.sequence, roles.name
END
    :extend => Garm::AuthorizationCache::Methods::HasMany do
    def push *roles
      @owner.save! if @owner.new_record?
      roles.flatten!
      roles.uniq!
      roles.map! { | r | Role[r] }
      roles.each do | role |
        RoleInheritance.create!(:child_role => @owner, :parent_role => role)
      end
      self
    end
    alias :<< :push

    def delete *roles
      return self if @owner.new_record?
      roles.flatten!
      roles.uniq!
      roles.map! { | r | Role[r] }
      RoleInheritance.destroy_all([ 'child_role_id = ? AND parent_role_id IN (?)', @owner, roles ])
      [ @owner, *roles ].each do | role |
        role.invalidate_role_inheritances!
      end
      self
    end

    def set! roles
      roles.map! { | r | Role[r] }
      current = @owner.new_record? ? [ ] : to_a
      del = current - roles
      add = roles - current
      delete *del
      push *add
      self
    end
  end
  def parent_role_ids= roles
    roles.map! { | r | String === r ? r.to_i : r }
    parent_roles.set! roles
    self
  end

  def parent_roles_deep
    role_inheritances.parent_roles_deep
  end

  before_destroy :destroy_role_inheritances!
  def destroy_role_inheritances!
    RoleInheritance.destroy_all(['child_role_id = ? OR parent_role_id = ?', self, self])
  end

  def invalidate_role_inheritances!
    role_inheritances.reload
    child_roles.reload
    parent_roles.reload
    self
  end

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

  def inherit_from_role! *roles
    RoleInheritance.transaction do
      sequence = role_inheritances.map{|ri| ri.sequence}.max || 0
      roles.each do | role |
        RoleInheritance.create!(:child_role => self, 
                                :parent_role => role,
                                :sequence => (sequence += 1))
      end
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
          raise ArgumentError, "Role #{role_name.inspect} : #{err.inspect}\n  #{err.backtrace * "\n  "}" 
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
              raise ArgumentError, "Capability #{cap_name.inspect} : #{err.inspect}\n  #{err.backtrace * "\n  "}" 
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
          raise ArgumentError, "Role #{role_name.inspect}: #{err.inspect}\n  #{err.backtrace * "\n  "}" 
        end
      end
    end
  end


end # class
