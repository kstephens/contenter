class AuthChange < ActiveRecord::Base
  belongs_to :user

  before_validation :initialize_user!
  def initialize_user!
    self.user ||= 
      UserTracking.current_user ||
      UserTracking.default_user
  end

end

