
class MimeTypesController < ApplicationController
  layout "streamlined"
  acts_as_streamlined
  include CrudController
end
