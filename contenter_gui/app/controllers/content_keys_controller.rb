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
                { :action => :new_content, :id => params[:id] }
               ]
    end
    menus
  end
  helper_method :_streamlined_side_menus


  # starts off a new piece of content with content_key initialized from self
  def new_content
    @content_key = ContentKey.find(params[:id])
    @content = Content.new(:content_key => @content_key)
    flash[:content_obj] = @content
    redirect_to :controller => :contents, :action => :new
  end

end
