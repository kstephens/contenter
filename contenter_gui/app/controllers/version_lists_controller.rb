
class RevisionListsController < ApplicationController
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

  def versions
    @revision_list = RevisionList.find(params[:id])
    @contents = @revision_list.content_versions.paginate(:page => params[:page])
  end

  def yaml
    api = Content::API.new()
    result = api.dump({ :revision_list_id => params[:id] }, :exact => true)
    render :text => result, :content_type => 'text/plain'
  end

end

