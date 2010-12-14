
class VersionListsController < ApplicationController
  layout "streamlined"
  acts_as_streamlined
  include CrudController
  require_capability :ACTION

  # Allows the user to add a note to and close this version list, if it is the session_version_list
  # A new session_version_list is automatically created on the next modification.
  #
  # FIXME: 
  # 1) This belongs in my_controller.rb
  # 2) If it must stay here it should probably check if creator == current_user or has_capability?("controller/<<version_lists>>/<<close>>/*")
  # 3) There should probably be a "closed" attribute that would prevent modifications or version additions.
  def close
    unless (vl = session_version_list) && vl.id == params[:id].to_i
      flash[:notice] = "Cannot close this version list" 
      redirect_to :action => 'show', :id => vl
      return
    end

    vl.tasks = params[:version_list][:tasks]
    vl.comment = params[:version_list][:comment]
    vl.validate_tasks_is_not_empty! if vl.class.requires_tasks
    
    # explicitly save and remove the session version list
    flush_session_version_list!
    
    case 
      when vl.errors.empty?
      # move them on 
      redirect_to :action => 'list'
      else
      flash[:error] = vl.errors.full_messages
    end
  end

  def _streamlined_side_menus
    menus = super
    if params[:id]
      menus << [ "Versions", { :action => :versions, :id => :id } ]
      menus << [ "YAML", { :action => :yaml, :id => :id } ]
    end
    menus
  end

  def versions
    @version_list = VersionList.find(params[:id])
    @contents = @version_list.content_versions.paginate(:page => params[:page])
  end

  def yaml
    api = Content::API.new()
    result = api.dump({ :version_list_id => params[:id] }, :exact => true)
    render :text => result, :content_type => 'text/plain'
  end

end

