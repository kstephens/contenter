
# Joins Role and User.
class RoleUser < ActiveRecord::Base
  include Garm::AuthorizationCache::Methods

  belongs_to :role, :extend => Garm::AuthorizationCache::Methods::BelongsTo
  belongs_to :user, :extend => Garm::AuthorizationCache::Methods::BelongsTo

  validates_presence_of :role
  validates_presence_of :user
  validates_presence_of :sequence

  before_validation :initialize_sequence!
  def initialize_sequence!
    self.sequence ||= 1
    self
  end

  def to_s
    "#{role.name} -> #{user.name}"
  end

end # class


