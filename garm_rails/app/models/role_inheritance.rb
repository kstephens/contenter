
# Joins Role and Role
class RoleInheritance < ActiveRecord::Base
  include Garm::AuthorizationCache::Methods

  belongs_to :child_role,  :class_name => 'Role', :extend => Garm::AuthorizationCache::Methods::BelongsTo
  belongs_to :parent_role, :class_name => 'Role', :extend => Garm::AuthorizationCache::Methods::BelongsTo

  validates_presence_of :child_role
  validates_presence_of :parent_role
  validates_presence_of :sequence

  before_validation :initialize_sequence!
  def initialize_sequence!
    self.sequence ||= 1
    self
  end

  after_save :invalidate_roles!
  after_destroy :invalidate_roles!
  def invalidate_roles!
    [ child_role, parent_role ].each do | role |
      role.role_inheritances.reload
      role.child_roles.reload
      role.parent_roles.reload
    end
  end

  def to_s
    "#{child_role.name} -> #{parent_role.name}"
  end

end # class


