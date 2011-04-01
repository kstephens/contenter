
# Joins Role and Role
class RoleInheritance < ActiveRecord::Base
  include Garm::AuthorizationCache::Methods

  belongs_to :child_role,  :class_name => 'Role', :extend => Garm::AuthorizationCache::Methods::BelongsTo
  belongs_to :parent_role, :class_name => 'Role', :extend => Garm::AuthorizationCache::Methods::BelongsTo

  validates_presence_of :child_role
  validates_presence_of :parent_role
  validates_presence_of :sequence

  validate :not_cyclical!
  def not_cyclical!
    case
    when parent_role && parent_role.parent_roles_deep.map{|r| r.id}.include?(child_role.id)
      errors.add(:child_role, "cannot be its own ancestor")
    when child_role && child_role.child_roles_deep.map{|r| r.id}.include?(parent_role.id)
      errors.add(:parent_role, "cannot be its own decendent")
    end
  end

  before_validation :initialize_sequence!
  def initialize_sequence!
    self.sequence ||= 1
    self
  end

  after_save :invalidate_roles!
  after_destroy :invalidate_roles!
  def invalidate_roles!
    # debugger if $stop_here
    [ child_role, parent_role ].each do | role |
      begin
        # $stderr.puts "role #{role.inspect} reloads"
        role.invalidate_role_inheritances!
      rescue Exception => err
        $stderr.puts "#{err.inspect}"
      end
    end
  end

  def to_s
    "#{child_role.name} -> #{parent_role.name}"
  end

end # class


