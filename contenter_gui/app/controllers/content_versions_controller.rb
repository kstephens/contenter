class ContentVersionsController < ApplicationController
  include ContentsControllerSupport

  def _streamlined_side_menus
    menus = super

    menus.delete_if do | x |
      x = x[0] if Array === x
      x = x.to_s
      x =~ /list|edit|new|destroy/i
    end

    if @content 
      menus << [
                "Current" + (@content.is_current_version? ? ' *' : ''),
                { :controller => :contents, :action => :show, :id => @content.content_id }
               ]
    end
    menus
  end
  helper_method :_streamlined_side_menus


end
