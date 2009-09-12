class ContentStatusesController < ApplicationController
  layout "streamlined"
  acts_as_streamlined
  include CrudController
  require_capability :ACTION
end
