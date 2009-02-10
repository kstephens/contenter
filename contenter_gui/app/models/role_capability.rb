class RoleCapability < ActiveRecord::Base
  belongs_to :role
  belongs_to :capability

  attr_accessor :role_name
  attr_accessor :capability_name

  before_validation :initialize_allow!
  def initialize_allow!
    self.allow = true if self.allow.nil?
  end

  before_validation :initialize_from_names!
  def initialize_from_names!
    if @role_name
      @role_name = @role_name.to_s
      self.role = 
        Role.find(:first, :conditions => { :name => @role_name }) ||
        Role.create!(:name => @role_name, :description => @role_name)
      @role_name = nil
    end
    if @capability_name
      @capability_name = @capability_name.to_s
      self.capability = 
        Capability.find(:first, :conditions => { :name => @capability_name }) ||
        Capability.create!(:name => @capability_name, :description => @capability_name)
      @capability_name = nil
    end
  end
end

