# This controller handles the login/logout function of the site.  
class SessionAdminController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  include Garm::Rails::ControllerHelper
  require_capability :ACTION
end
