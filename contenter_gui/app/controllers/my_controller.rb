class MyController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  layout "streamlined"
  # acts_as_streamlined
  require_capability :ACTION

  def _streamlined_side_menus
    menus = [ ]
    menus << :changes
    menus
  end

  def changes
    if (x = session_revision_list) && x.id
      redirect_to :controller => :revision_lists, :action => :show, :id => x
    else
      render :action => 'changes'
    end
  end
end


