class ContentsController < ApplicationController
  layout "streamlined"
  acts_as_streamlined
  include CrudController

  before_filter :verify_authenticity_token, :except => [ :auto_complete_for_content_content_key_code ]

  require_capability :ACTION, :except => [ :add_filter, :delete_filter, :clear_all_filters ]

  def advanced_filtering
    params[:action] == 'list'
  end
  helper_method :advanced_filtering


  def streamlined_side_menus
    menus = super
    if params[:id]
      menus +=
        [
         [
          "YAML",
          { :controller => :api, :action => :dump, :id => params[:id] }
         ],
         [
          "Raw",
          { :action => :data, :id => params[:id] }
         ],
        ]
    end
    menus
  end
  helper_method :streamlined_side_menus


  def new
    # $stderr.puts "  EDIT #{params.inspect}"
    opts = { 
      :content_type_id => params[:content_type_id],
      :content_key_id  => params[:content_key_id],
    }
    opts.keys.each do | k |
      opts.delete(k) if opts[k].blank?
    end
    @content = Content.new(opts)
    render :action => 'edit'
  end


  def edit
    # $stderr.puts "  EDIT #{params.inspect}"
    @content = Content.find(params[:id])
    render :action => 'edit'
  end


  def update
    # $stderr.puts "  UPDATE #{params.inspect}"
    @content = Content.find(params[:id]) || (raise ArgumentError)
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

end
