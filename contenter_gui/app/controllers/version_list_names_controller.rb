
class RevisionListNamesController < ApplicationController
  layout "streamlined"
  acts_as_streamlined
  # include CrudController
  require_capability :ACTION

  def _streamlined_side_menus
    menus = super
    if params[:id]
      menus << [ "Versions", { :action => :versions, :id => :id } ]
      menus << [ "YAML", { :action => :yaml, :id => :id } ]
    end
    menus
  end

  def yaml
    @revision_list_name = RevisionListName.find(params[:id])
    redirect_to :controller => :revision_lists, :action => :yaml, :id => @revision_list_name.revision_list_id
  end

  def versions
    @revision_list_name = RevisionListName.find(params[:id])
    redirect_to :controller => :revision_lists, :action => :versions, :id => @revision_list_name.revision_list_id
  end

end

