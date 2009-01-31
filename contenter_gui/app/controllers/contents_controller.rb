class ContentsController < ApplicationController
  layout "streamlined"
  acts_as_streamlined
  include CrudController

  before_filter :verify_authenticity_token, :except => [ :auto_complete_for_content_content_key_code ]

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

=begin
  def new
    render :action => 'new'
  end

  def create
    @content = Content.new(params)
    if @content.save
      redirect_to :show, :id => @content
    else
      redirect_to :new
    end
  end
=end


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
