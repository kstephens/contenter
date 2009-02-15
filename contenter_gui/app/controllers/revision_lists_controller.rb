
class RevisionListsController < ApplicationController
  layout "streamlined"
  acts_as_streamlined
  # include CrudController
  require_capability :ACTION

  def _streamlined_side_menus
    menus = super
    menus << [ "Versions", { :action => :versions, :id => :id } ]
    menus
  end

  def versions
    @revision_list = RevisionList.find(params[:id])
    @contents = @revision_list.content_versions.paginate(:page => params[:page])
  end

end

