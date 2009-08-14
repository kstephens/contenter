class ContentVersionsController < ApplicationController
  layout "streamlined"
  acts_as_streamlined
  include CrudController

  before_filter :verify_authenticity_token, :except => [ :auto_complete_for_content_content_key_code ]

  require_capability :ACTION, :except => [ :add_filter, :delete_filter, :clear_all_filters ]

  before_filter :translate_uuid!, :only => [ :show, :data, :mime_type ]
  def translate_uuid!
    if ! (x = params[:id]).blank? && (x = x.to_s) =~ /-/
      x = x.sub(/-(\d+)\Z/, '')
      version = $1.to_i
      x = ContentVersion.find(:all, 
                              :conditions => [ 'uuid LIKE ? AND version = ?', x + '%', version ],
                              :limit => 2)
      x = x.size == 1 ? x.first : nil
      x &&= x.id
      params[:id] = x
    end
  end


  def advanced_filtering
    params[:action] == 'list'
  end
  helper_method :advanced_filtering


  def _streamlined_side_menus
    menus = super

    menus.delete_if do | x |
      x = x[0] if Array === x
      x = x.to_s
      x =~ /edit|new/i
    end

    if params[:id]
      translate_uuid!
      @content ||= ContentVersion.find(params[:id])
      menus << [
                "YAML",
                { :controller => :api, :action => :dump, :id => @content.content_id, :version => @content.version }
               ]
      menus << [
                "Raw",
                { :action => :data, :id => :id }
               ]
      menus << [
                "Current" + (@content.is_current_version? ? ' *' : ''),
                { :controller => :contents, :action => :show, :id => @content.content_id }
               ]
    end
    menus
  end
  helper_method :_streamlined_side_menus


  def data
    @content ||= ContentVersion.find(params[:id])
    content_type = @content.mime_type.code
    content_type = 'text/plain' unless content_type =~ /\//
    render :text => @content.data, :content_type => content_type
  end


  def mime_type
    @content ||= ContentVersion.find(params[:id])
    content_type = @content.mime_type.code
    render :text => content_type, :content_type => 'text/plain'
  end


end
