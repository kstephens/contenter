class ContentsController < ApplicationController
  layout "streamlined"
  acts_as_streamlined
  include CrudController

  before_filter :verify_authenticity_token, :except => [ :auto_complete_for_content_content_key_code ]

  around_filter :track_in_session_version_list, :only => [ :update, :create, :delete ]

  require_capability :ACTION, :except => [ :add_filter, :delete_filter, :clear_all_filters ]

  before_filter :translate_uuid!, :only => [ :show, :edit, :edit_as_new, :update, :data, :mime_type ]

  # Search for any uuid that might match.
  def translate_uuid!
    if ! (x = params[:id]).blank? && (x = x.to_s) =~ /-/
      x = Content.find(:all, 
                       :conditions => [ 'uuid LIKE ?', x + '%' ],
                       :limit => 2)
      x = x.size == 1 ? x.first : nil
      x &&= x.id
      params[:id] = x
    end
  end


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
          "Same",
          { :action => :same, :id => :id }
         ],
        ]
    end
    menus
  end
  helper_method :_streamlined_side_menus

  ####################################################################

  def new
    # $stderr.puts "  EDIT #{params.inspect}"
    opts = { 
      :content_type_id => params[:content_type_id],
      :content_key_id  => params[:content_key_id],
    }
    opts.keys.each do | k |
      opts.delete(k) if opts[k].blank?
    end
    @content = flash[:content_obj] || Content.new(opts)
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


  def edit
    @content = Content.find(params[:id])
    render :action => 'edit'
  end


  def update
    # $stderr.puts "  UPDATE #{params.inspect}"
    @content = Content.find(params[:id]) || (raise ArgumentError)

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
    if @content.save
      flash[:notice] = "#{model_name.titleize} was successfully updated."
      redirect_to :action => 'show', :id => @content
    else
      flash[:notice] = "#{model_name.titleize} had errors."
      redirect_to :action => 'edit', :id => @content
    end
  end


  def edit_as_new
    @content = Content.find(params[:id])
    render :action => 'new'
  end


  # Creates a new version of this content from an older version, effectively
  # rolling back the content
  def edit_from_version version_id = params[:id]
    cv = Content::Version.find(version_id)
    @content = cv.content
    #set attributes from this version
    cv.content_values.each_pair{|k,v| @content.send("#{k}=", v) }
    render :action => 'edit'
  end
  
  def data
    @content = Content.find(params[:id])
    content_type = @content.mime_type.code
    content_type = 'text/plain' unless content_type =~ /\//
    render :text => @content.data, :content_type => content_type
  end


  def mime_type
    @content = Content.find(params[:id])
    content_type = @content.mime_type.code
    render :text => content_type, :content_type => 'text/plain'
  end


  def same
    @content = Content.find(params[:id])
    redirect_to :controller => :search, :action => :search, :id => "md5sum:#{@content.md5sum}"
  end


  # SUPPORT FOR AUTO COMPLETE

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


end
