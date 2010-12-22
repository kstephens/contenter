class ContentTypesController < ApplicationController
  layout "streamlined"
  acts_as_streamlined
  include CrudController
  require_capability :ACTION

  def _side_menus
    menus = super
    if params[:id]
      instance = ContentType.find(params[:id])
      menus << [
                "New Content",
                { :controller => :contents, :action => :new, :content_type_id => params[:id] }
               ]
      menus << [
                "Approve",
                { :controller => :workflow, :action => :list, :id => :approve, :content_type => instance.code }
               ]
      menus << [
                "Release",
                { :controller => :workflow, :action => :list, :id => :release, :content_type => instance.code }
               ]
    end
    menus
  end
  helper_method :_side_menus


  before_filter :find_object, :only => [ :upload, :upload_submit ]
  before_filter :check_capability_on_model_instance!, :only => [ :upload, :upload_submit ]

  def upload
    @upload = Upload.new
    @upload.content_type = @content_type
    if respond_to?(:plugin_upload) && respond_to?(:plugin_upload_submit)
      plugin_upload
    else
      flash[:error] = "Not implemented."
    end
  end

  def upload_submit
    # $stderr.puts "params = #{params.inspect}"
    @upload = Upload.new(params[:upload])
    @upload.content_type = @content_type
    if respond_to?(:plugin_upload_submit)
      @api = nil
      @version_list = nil
      
      begin
        VersionList.track_changes_in(
                                     lambda { | |
                                       @version_list ||= 
                                       VersionList.new(:comment => "Via bulk upload: #{@content_type}: #{@upload.upload.original_filename}: #{@upload.comment}")
                                     }
                                     ) do 
          plugin_upload_submit 
        end
      rescue Exception => err
        flash[:error] = err.to_s
        $stderr.puts "#{self.class.name} #{params[:action]} ERROR #{err.inspect}\n#{err.backtrace * "\n"}"
            
      ensure
        if @version_list && @version_list.id && @api
          @api.result[:version_list_id] = @version_list.id
        end
      end
    else
      flash[:error] = "Not implemented."
    end
  rescue Contenter::Error => err
    flash[:error] = "Error"
    @error = err.inspect
  end
end

