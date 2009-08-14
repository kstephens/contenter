require 'content_ui'
Content.class_eval { include ContentAdditions }

class SearchController < ApplicationController
  layout "streamlined"
  require_capability :ACTION

  def _streamlined_side_menus
    [ ]
  end
  helper_method :_streamlined_side_menus


  def index
    search
  end


  def search
    if ! (x = params[:_] || params[:id]).blank?
      params[:search] = { :search => x }
    end
    render :action => :search
  end

end


