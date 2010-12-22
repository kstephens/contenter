class MyController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  layout "streamlined"
  # acts_as_streamlined
  require_capability :ACTION

  def _side_menus
    menus = [ ]
    menus << :changes
    menus
  end

  def changes
    if (x = session_version_list) && x.id
      redirect_to :controller => :version_lists, :action => :show, :id => x
    else
      render :action => 'changes'
    end
  end
end


