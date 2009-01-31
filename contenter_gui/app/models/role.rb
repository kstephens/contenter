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

    # Try default role.
    if name != '__default__'
      allow = Role['__default__'].has_capability?(cap)
      return allow unless allow.nil?
    end

    # Inconclusive.
    nil
  end


  # Returns a Hash of Capability name to allowance.
  def capability
    @capability ||=
      role_capabilities.inject({ }) do | h, rc |
      h[rc.capability.name.dup.freeze] = rc.allow
      h
    end.freeze
  end

end

