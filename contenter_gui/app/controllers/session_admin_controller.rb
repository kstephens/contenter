# This controller handles the login/logout function of the site.  
class SessionAdminController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  layout "streamlined"
  acts_as_streamlined
  require_capability :ACTION
end
