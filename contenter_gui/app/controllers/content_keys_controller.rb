class ContentKeysController < ApplicationController
  layout "streamlined"
  acts_as_streamlined
  include CrudController
  require_capability :ACTION

  def _streamlined_side_menus
    menus = super
    if params[:id]
      menus << [
                "New Content",
                { :controller => :contents, :action => :new, :content_key_id => params[:id] }
               ]
    end
    menus
  end
  helper_method :_streamlined_side_menus


end
