require 'contenter/error'

require 'contenter/uri'

module ContentsControllerSupport
  def self.included target
    super
    target.extend(ClassMethods)
    target.class_eval do
      layout "streamlined"
      acts_as_streamlined
      include CrudController
      include DestroyControllerActions
      include InstanceMethods

      before_filter :verify_authenticity_token, :except => [ :auto_complete_for_content_content_key_code ]
      
      around_filter :track_in_session_version_list, :only => [ :update, :create, :delete ]

      require_capability :ACTION, :except => [ :destroy_prompt, :add_filter, :delete_filter, :clear_all_filters ]

      before_filter :find_object,              :only => [ :show, :edit, :update, :yaml, :data, :mime_type, :same, :preview, :actual, :status_action ]
      before_filter :find_object_not_found_ok, :only => [ :new ]

      before_filter :remove_unsettable_params!, :only => [ :create, :update ]

      before_filter :check_capability_on_content_type!, :except => [ :new, :create ]
    end
  end


  module ClassMethods
  end

  module InstanceMethods
=begin
  def advanced_filtering
    params[:action] == 'list'
  end
  helper_method :advanced_filtering
=end


  def _side_menus
    menus = super
    if params[:id]
      menus +=
        [
         [
          "YAML",
          { :action => :yaml, :id => :id }
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

    @content && Content === @content && @content.id && @content.allowed_status_actions.each do |a|
      menus += [
        [
         a.to_s.capitalize, 
         { :controller => 'workflow', :action => :list, :status_action => a, :content_id => @content.id }, 
        ]
      ]
    end

    menus
  end


  def allow_data_upload?
    true
  end


  def process_upload_data! params = nil
    params ||= self.params

    copy_from_uuid = params[:content].delete(:copy_from_uuid)
    data_upload = params[:content].delete(:data_upload)
    data_upload_url = params[:content].delete(:data_upload_url)
    data_upload_url &&= data_upload_url.strip

    case
      # Copy data from existing record.
    when ! copy_from_uuid.blank?
      params[:content][:data] ||= Content.find(:first, :conditions => { :uuid => copy_from_uuid }).data
      $stderr.puts "Setting from copy_from_uuid #{copy_from_uuid}."

      # Upload from a URL.
    when ! data_upload_url.blank?
      data = URI.parse(data_upload_url).read
      params[:content][:data] = data
      params[:content][:filename] = data_upload_url[0 .. 255]
      params[:content][:content_key_code] = params[:content][:filename] if params[:content][:content_key_code].blank?

      mime_type = (data.content_type rescue nil) || 
        Contenter::ContentConverter::Content.new(:data => data_upload_data).mime_type
      params[:content][:mime_type_id] = MimeType[mime_type].to_id

      # Handle data_upload field.
      # Determine mime_type from uploaded data.
    when ! data_upload.blank?
      # $stderr.puts "Setting from data_upload."
      data_upload_data = data_upload.read
      params[:content][:data] = data_upload_data
      params[:content][:filename] = data_upload.original_filename[0 .. 255]

      mime_type = Contenter::ContentConverter::Content.new(:data => data_upload_data).mime_type
      params[:content][:mime_type_id] = MimeType[mime_type].to_id
    end
  end


  def same
    redirect_to :controller => :search, :action => :search, :_ => "md5sum:#{@content.md5sum}"
  end

  def yaml
    contents = @content
    contents = [ contents ] unless Enumerable === contents
    result = Contenter::Bulk.new(:document => { :contents => contents }).render_yaml
    result = result.string # StringIO
    render :text => result, :content_type => 'text/plain'
  end

  def data
    content_type = @content.mime_type.to_s
    content_type = 'text/plain' unless content_type =~ /\//
    unless fresh_when(:etag => @content.md5sum)
      render :text => @content.data, :content_type => content_type
    end
  end

  def mime_type
    content_type = @content.mime_type.to_s
    render :text => content_type, :content_type => 'text/plain'
  end


  def preview
    if respond_to?(:plugin_preview)
      plugin_preview
    else
      flash[:error] = "Not implemented."
    end
  end


  def actual
    if respond_to?(:plugin_actual)
      plugin_actual
    else
      flash[:error] = "Not implemented."
    end
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
    # $stderr.puts "#{self.class.name} find_object #{params.inspect}"

    oid ||= params[:id]

    # Handle /content/show/1-64x64.png
    oid = oid.to_s.dup
    @convert_options = nil
    if oid.sub!(/(\.[^\.\/]+)\Z/, '') || params[:format]
      @convert_options ||= { }
      @convert_options[:suffix] = ((x = params[:format]) && ".#{x}") || $1
    end
    # Handle /content/show/1234[:content] as @content.data_hash[:content].
    if oid.sub!(/\[:(\w+)\]\Z/, '')
      @data_hash_index = $1.to_sym
    end
    if oid.sub!(/-(\d+)?x(\d+)?\Z/i, '')
      @convert_options ||= { }
      opts = @convert_options[:options] ||= { }
      opts[:width]  = $1 && $1.to_i
      opts[:height] = $2 && $2.to_i
    end
    if oid.sub!(/-r(\d+)\Z/i, '')
      @convert_options ||= { }
      opts = @convert_options[:options] ||= { }
      opts[:rotate] = $1.to_i
    end
    # $stderr.puts "convert_options = #{@convert_options.inspect}"
    oid = oid.to_i if oid.to_i.to_s == oid

    case
      # Search for any unique content that might match.
      # e.g.: /contents/show?content_type=phrase&content_key=hello&language=en
    when oid.blank? && ! params[:content_type].blank? 
      @content = Content::Query.new(:params => params, :exact => true).find(:all, :limit => 2)

      # Search for any uuid that might match.
    when ! (x = oid).blank? && (x = x.to_s) =~ /-/
      @content = self.model.find(:all, 
                              :conditions => [ 'uuid LIKE ?', x + '%' ],
                              :limit => 2)
    else
      @content = self.model.find(oid)
    end

    if Array === @content
      @content = 
        case @content.size
        when 0
          nil
        when 1
          @content = @content.first
        else
          raise Contenter::Error::Ambiguous, "Cannot find unambigous content for #{params.inspect}"
        end
    end

    raise Contenter::Error::NotFound, "Cannot find Content #{oid.inspect} (params = #{params.inspect})" unless @content
    params[:id] = @content.id

    @from_object = nil
    case
    when v = params[:from_version]
      @from_object = @content.versions.find(:first, :conditions => { :version => v }) or
        raise Contenter::Error::NotFound, "Cannot find version for from_version=#{v.inspect}"
    when fid = params[:from_id]
      @from_object = Content.find(fid) or
        raise Contenter::Error::NotFound, "Cannot find Content for from_id=#{fid.inspect}"
    end

    # Mixin any Content plugins.
    @content.plugin

    # Mixin any controller plugins.
    after_object_find!(@content)

    # Keep the original content object around after conversions.
    @content_object = @content 

    # Process data_hash index as a conversion.
    if @data_hash_index
      @data_hash_data = 
        ((@content_object.data_hash rescue nil) || { })[@data_hash_index] ||
        ''

      # SIGH...
      #
      # /usr/bin/file does not recognize HTML fragments as HTML.
      # so /contents/data/1234[:content] on a seo_content record.
      # does not produce the result one would expect.
      #
      # SO....
      #
      # fake a <html><head></head><body>...
      #
      if @data_hash_data =~ /\A\s*<(div|span|h\d|table|hr|ul|ol|p[ >\/])/
        @data_hash_data = "<html><head></head><body>#{@data_hash_data}</body></html>"
      end

      # Create a dummy content object for the data_hash content.
      @data_hash_content = 
        Contenter::ContentConverter::Content.new(
                                                 :content_key => "#{@content_object.content_key}[:#{@data_hash_index}]", 
                                                 :data => @data_hash_data, 
                                                 :uuid => @content_object.uuid,
                                                 :verbose => true)

      # Pass through other attributes to original content object.
      @data_hash_content._delegate = @content_object
      @content = @data_hash_content
    end

    # Handle conversions.
    if @convert_options
      @convert_options[:verbose] = true
      @content = ContentConversion.convert(@content, @convert_options)

      # Pass through other attributes to original content object.
      @content._delegate = @content_object if @content.respond_to?(:_delegate)
    end

    # For ContentVersionsController.
    @content_version = @content

    @content
  end

  def find_object_not_found_ok oid = nil
    find_object oid
  rescue ActiveRecord::RecordNotFound, Contenter::Error::NotFound
    nil
  end

  def remove_unsettable_params!
    if c = params[:content]
      c.delete(:uuid)
      c.delete(:md5sum)
      c.delete(:content_status)
      c.delete(:content_status_id)
      c.delete(:creator)
      c.delete(:creator_user_id)
      c.delete(:updater)
      c.delete(:updater_user_id)
    end
  end
  end
end
