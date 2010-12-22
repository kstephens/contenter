class RoleCapabilitiesController < ApplicationController
  include Garm::Rails::ControllerHelper
  require_capability :ACTION
end

