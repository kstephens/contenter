class Role < ActiveRecord::Base
  include CapabilityHelper

  has_many :role_capabilities

  validates_format_of :name, :with => /\A([a-z0-9_])+\Z/i
  validates_presence_of :name
  validates_presence_of :description


  # Lookup a Role by id or name.
  def self.[](x)
    case x
    when Integer
      self.find(x) ||
        raise("Cannot find #{self} id=#{x.inspect}")
    when String, Symbol
      self.find(:first, :conditions => { :name => x.to_s } ) ||
        raise("Cannot find #{self} name=#{x.inspect}")
    end
  end


  # Returns true if this Role allows the Capability.
  # Returns false if this Role does not allow the Capability.
  # Returns nil if its inconclusive.
  def has_capability? cap
    cap = cap.name if cap.respond_to?(:name)
    cap = cap.to_s unless String === cap
    
    ((@has_capability ||= { })[cap] ||= 
     [ _has_capability?(cap) ]
     ).first
  end


  # Uncached version.
  def _has_capability? cap
    # Try immediate capabilities.
    caps = capability_expand(cap)
    caps.each do | cap |
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

  # Returns a Hash of Capability name to allowance.
  def capability
    @capability ||=
      role_capabilities.inject({ }) do | h, rc |
      h[rc.capability.name.dup.freeze] = rc.allow
      h
    end.freeze
  end

  

  # See db/*_create_default_roles.rb as an example.
  def self.build_role_capability *role_capability
    role_capability.each do | (role, desc, caps) |
      $stderr.puts "  Role: #{role.inspect}"
      role = 
        Role.find(:first, :conditions => { :name => role }) || 
        Role.create!(:name => role, :description => desc || role)
      role.update_attribute(:description, desc) if role.description.blank? && ! desc.blank?

      if Array === caps
        caps = caps.inject({ }) { | h, cap | h[cap] = true; h }
      end
      caps.each do | cap, allow |
        $stderr.puts "    Capability: #{cap.inspect} => #{allow.inspect}"
        cap = 
          Capability.find(:first, :conditions => { :name => cap } ) || 
          Capability.create!(:name => cap, :description => cap)
        role_cap = RoleCapability.create!(:role => role, :capability => cap, :allow => allow)
      end
    end
  end

  # See db/*_create_default_roles.rb as an example.
  def self.build_user_role user, *roles
    unless User === user
      user = User.find(:first, :conditions => { :login => user }) || 
        raise("Cannot find user #{user.inspect}")
    end
    roles.each do | role |
      role = 
        Role.find(:first, :conditions => { :name => role }) || 
        Role.create!(:name => role, :description => role)
      user.roles << role
    end
  end


end # class

