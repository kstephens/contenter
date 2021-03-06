class Capability < ActiveRecord::Base
  include Garm::AuthorizationCache::Methods

  validates_format_of :name, :with => /\A([a-z0-9_]+|\*|\+)(\/([a-z0-9_]+|\*|\+))*(\?([^\?]+))?\Z/i
  validates_presence_of :name
  validates_presence_of :description

  has_many :role_capabilities

  has_many :roles, :through => :role_capabilities, :extend => Garm::AuthorizationCache::Methods::HasMany


  # Lookup a Capability by id or login.
  # Returns nil if cannot be found.
  # Lookup a Role by id or name.
  def self.[](x)
    Garm::AuthorizationCache.current.capability(x)
  end

  def to_s
    name
  end

end
