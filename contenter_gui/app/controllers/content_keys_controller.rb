class ContentKeysController < ApplicationController
  layout "streamlined"
  acts_as_streamlined

  # adds redirection to a successful create
  render_filter :create, :success => Proc.new {
    redirect_to :action => 'show', :id => @content_key
  }

  include CrudController
  include DestroyControllerActions
  require_capability :ACTION, :except => [ :destroy_prompt, ]

  def _side_menus
    menus = super
    if params[:id]
      menus << [
                "New Content",
                { :controller => :contents, :action => :new, :content_key_id => params[:id] }
               ]
    end
    menus
  end
  helper_method :_side_menus

end
