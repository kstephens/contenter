class RoleCapabilitiesController < ApplicationController
  layout "streamlined"
  acts_as_streamlined
  require_capability :ACTION
end

