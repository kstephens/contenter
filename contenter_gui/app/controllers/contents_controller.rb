require 'contenter/error'

class ContentsController < ApplicationController
  include ContentsControllerSupport

  ####################################################################


  def index; end

  def list
    redirect_to :controller => :search
  end


  # new/<id> means create a new object using <id> as a prototype.
  # new?content_key_id=<kid> create a new object using the specified content_key.
  def new
    # $stderr.puts "  EDIT #{params.inspect}"
    opts = { 
      :content_type_id => params[:content_type_id],
      :content_key_id  => params[:content_key_id],
    }
    opts.keys.each do | k |
      opts.delete(k) if opts[k].blank?
    end

    @content ||= Content.new(opts)
    @content.copy_from!(@from_object) if @from_object
    @content.copy_from_uuid = @content.uuid
    @content.id = @content.uuid = @content.version = nil

    return false unless check_capability_on_content_type!

    render :action => 'new'
  end


  def create
    process_upload_data!
    data = params[:content].delete(:data)

    @content = Content.new(params[:content])
    @content.data = @content.plugin.params_to_data(data)

    return false unless check_capability_on_content_type!
   
    @content.validate_tasks_is_not_empty! if @content.class.requires_tasks

    if @content.save
      flash[:notice] = "#{model_name.titleize} was successfully updated."
      redirect_to :action => 'show', :id => @content
    else
      flash[:notice] = "#{model_name.titleize} had errors."
      redirect_to :action => 'new', :id => @content
    end
  end


  # if ?from_version=v or ?from_id=id,
  # copy data from the version of Content specified.
  def edit
    return false unless check_capability_on_content_type!

    @content.copy_from!(@from_object) if @from_object

    render :action => 'edit'
  end


  def update
    return false unless check_capability_on_content_type!

    process_upload_data!

    # Example:
    #
    # The Plugin::Null will use a single field that is returned in params[:content][:data].
    #
    # params[:content][:data] == 'new data'
    # params_to_attributes(params[:content][:data]) => 'new data'
    # 
    #
    # Email:
    #
    # params[:content][:data][:subject] = 'Yo i heard you were interested in...'
    # params[:content][:data][:body] = 'Some spam for yall'
    # params_to_attributes(params[:content][:data]) => <<'END'
    # ----
    # subject: 'Yo i heard you were interested in...'
    # body: 'Some spam for yall'
    #
    params[:content][:data] = @content.plugin.params_to_data(params[:content][:data])

    # @content.content_type_id = params[:content][:content_type_id]
    @content.attributes = params[:content]
    @content.validate_tasks_is_not_empty! if @content.class.requires_tasks

    case
    when ! @content.content_changed?
      flash[:notice] = "#{model_name.titleize} was unchanged."
      redirect_to :action => 'show', :id => @content
    when @content.save
      flash[:notice] = "#{model_name.titleize} was successfully updated."
      redirect_to :action => 'show', :id => @content
    else
      flash[:error] = "#{model_name.titleize} had errors."
      redirect_to :action => 'edit', :id => @content
    end
  end

end
