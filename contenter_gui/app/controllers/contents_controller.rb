class ContentsController < ApplicationController
  layout "streamlined"
  acts_as_streamlined
  include CrudController

  before_filter :verify_authenticity_token, :except => [ :auto_complete_for_content_content_key_code ]

  around_filter :track_in_session_version_list, :only => [ :update, :create, :delete ]

  require_capability :ACTION, :except => [ :add_filter, :delete_filter, :clear_all_filters ]

  before_filter :find_object,              :only => [ :show, :edit, :update, :data, :mime_type, :same ]
  before_filter :find_object_not_found_ok, :only => [ :new ]
  before_filter :remove_unsettable_params, :only => [ :create, :update ]

  ####################################################################

  def advanced_filtering
    params[:action] == 'list'
  end
  helper_method :advanced_filtering


  def _streamlined_side_menus
    menus = super
    if params[:id]
      menus +=
        [
         [
          "YAML",
          { :controller => :api, :action => :dump, :id => :id }
         ],
         [
          "Raw",
          { :action => :data, :id => :id }
         ],
         [
          "Find Duplicates",
          { :action => :same, :id => :id }
         ],
        ]
    end
    menus
  end
  helper_method :_streamlined_side_menus

  ####################################################################

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
    render :action => 'new'
  end


  def create
    data = params[:content].delete(:data)
    @content = Content.new(params[:content])
    @content.data = @content.plugin.params_to_data(data)
   
    if @content.save
      flash[:notice] = "#{model_name.titleize} was successfully updated."
      redirect_to :action => 'show', :id => @content
    else
      flash[:notice] = "#{model_name.titleize} had errors."
      redirect_to :action => 'new', :id => @content
    end
  end


  # if ?from_version=v copy data from the version of Content specified.
  def edit
    @content.copy_from!(@from_object) if @from_object
    render :action => 'edit'
  end


  def update
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
    @content.update_attributes(params[:content])
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


  def data
    content_type = @content.mime_type.code
    content_type = 'text/plain' unless content_type =~ /\//
    render :text => @content.data, :content_type => content_type
  end


  def mime_type
    content_type = @content.mime_type.code
    render :text => content_type, :content_type => 'text/plain'
  end


  def same
    redirect_to :controller => :search, :action => :search, :_ => "md5sum:#{@content.md5sum}"
  end


  # support for content_key auto-complete.
  def auto_complete_for_content_content_key_code
    # $stderr.puts "  params = #{params.inspect}"
    find_options = {
      :conditions => [ 'LOWER(code) LIKE ? AND content_type_id = ?', 
                       '%' + (params[:content][:content_key_code] || '').downcase + '%',
                       params[:content][:content_type_id] || params[:id],
                     ],
      :order => "code ASC",
      :limit => 15,
    }

    @items = ContentKey.find(:all, find_options)
    # $stderr.puts "  items = #{@items.map{|x| x.code}.inspect}"
    render :inline => "<%= auto_complete_result @items, 'code' %>"
  end


  def find_object oid = nil
    oid ||= params[:id]

    # Search for any uuid that might match.
    if ! (x = oid).blank? && (x = x.to_s) =~ /-/
      x = Content.find(:all, 
                       :conditions => [ 'uuid LIKE ?', x + '%' ],
                       :limit => 2)
      x = x.size == 1 ? x.first : nil
      x &&= x.id
      params[:id] = oid = x if x
    end

    @content = Content.find(oid) || (raise Content::Error::NotFound, "Cannot find Content #{oid.inspect}")

    @from_object = nil
    case
    when v = params[:from_version]
      @from_object = @content.versions.find(:first, :conditions => { :version => v }) || (raise Content::Error::NotFound, "Cannot find version for from_version=#{v.inspect}")
    when did = params[:from_id]
      @from_object = Content.find(fid) || (raise Content::Error::NotFound, "Cannot find Content for from_id=#{did.inspect}")
    end
    @content
  end
  helper_method :find_object

  def find_object_not_found_ok oid = nil
    find_object oid
  rescue ActiveRecord::RecordNotFound, Content::Error::NotFound
    nil
  end
  helper_method :find_object_not_found_ok

  def remove_unsettable_params
    if c = params[:content]
      c.delete(:content_status_id)
      c.delete(:content_status)
    end
  end
  helper_method :remove_unsettable_params
end
