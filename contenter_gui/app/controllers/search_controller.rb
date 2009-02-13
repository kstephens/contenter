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
    @search = SearchObject.new(params[:search] || session[:search])
    session[:search] = @search.opts

    search_by = (@search.search || '').dup
    search_by.gsub!(/\A\s+|\s+\Z/, '')
    
    unless search_by.blank?
      search_by = search_by.dup
      
      search_opts = { }
      if search_by.sub!(/content_type:([a-z]+)\s*/i, '')
        search_opts[:content_type] = $1
      end
      
      search_by.gsub!(/\A\s+|\s+\Z/, '')
      unless search_by.blank?
        search_opts[:content_key] = search_by
        search_opts[:data] = search_by
      end

      @search_options = 
        [ 
         :all,
         search_opts,
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



