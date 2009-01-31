class RoleCapability < ActiveRecord::Base
  belongs_to :role
  belongs_to :capability

  before_save :initialize_allow!
  def initialize_allow!
    self.allow = true if self.allow.nil?
  end

end

