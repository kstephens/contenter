
class VersionListNamesController < ApplicationController
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
    @version_list_name = VersionListName.find(params[:id])
    redirect_to :controller => :version_lists, :action => :yaml, :id => @version_list_name.version_list_id
  end

  def versions
    @version_list_name = VersionListName.find(params[:id])
    redirect_to :controller => :version_lists, :action => :versions, :id => @version_list_name.version_list_id
  end

end

