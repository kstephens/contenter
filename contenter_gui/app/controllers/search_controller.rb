require 'content_ui'
Content.class_eval { include ContentAdditions }

class SearchController < ApplicationController
  layout "streamlined"
  require_capability :ACTION

  def streamlined_side_menus
    [ ]
  end
  helper_method :streamlined_side_menus


  def index
    search
  end


  def search
    @search = SearchObject.new(params[:search] || session[:search])
    session[:search] = @search.opts
    unless (search_by = @search.search).blank?
      search_by = "#{search_by}"
      @search_options = 
        [ 
         :all,
         { :content_key => search_by, :data => search_by },
         { :like => true, :or => true },
        ]
    end
    render :action => :search
  end

end


class SearchObject
  attr_accessor :search
  
  attr_reader :opts

  def initialize opts
    @search = ''
    opts ||= { }
    @opts = opts
    opts.each do | k, v |
      send("#{k}=", v)
    end
  end
end



