module ContentAdditions
  ####################################################################
  # View/Controller helpers
  #

  def version_as_html
    x = version.to_s
    x
  end

  ####################################################################
  # Streamline support
  #

  def streamlined_name *args
    content_key.code
  end

  
  STR_ESC = {
    "\\" => "\\\\",
    "\r" => "\\r",
    "\n" => "\\n",
  }.freeze

  def is_binary?
    ((x = mime_type) && x.is_binary?) ||
      ((x = content_type) && (x = x.mime_type) && x.is_binary?)
  end

  def is_image?
    ((x = mime_type) && x.is_image?) ||
      ((x = content_type) && (x = x.mime_type) && x.is_image?)
  end

  def data_short max_size = nil, data_for_list = nil
    plugin # force mixin # FIXME use some callback like after_find?
    case 
    when is_image?
      return data_formatted(:img_src_opts => "-32x32.png", :no_link => true)
    when is_binary?
      return "<i>{binary}</i>"
    end
    max_size ||= 32
    # $stderr.puts " ### data_for_list=#{self.data_for_list.inspect}"
    data_for_list ||= self.data_for_list || ''
    x = data_for_list
    x =~ /\A[\n\r\s]+(.*)/m
    x = $1 || x
    if x != data_for_list || x.size > max_size
      # Handle UTF-8: do not truncate in the middle of a UTF-8 sequence.
      while max_size < x.size && (c = x[max_size]) && c > 127
        max_size += 1
      end
      x = x[0 .. max_size] + '...'
      x.gsub!(/[\\\r\n]/){ | c | STR_ESC[c] } 
    end
    x = ERB::Util.h(x)
    x
  end

  EMPTY_HASH = { }.freeze

  def data_formatted opts = EMPTY_HASH
    if is_image?
      case self
      when Content::Version
        uri = "/content_versions/data/#{id}"
      else
        uri = "/contents/data/#{uuid || copy_from_uuid}"
      end
      result = %Q{<img src="#{uri}#{opts[:img_src_opts]}" />}
      result = %Q{<a href="#{uri}">#{result}</a>} unless opts[:no_link]
    else
      result = "<pre>#{ERB::Util.h(data || '')}</pre>"
    end
    # $stderr.puts " ### data_formatted=#{result.inspect}"
    result
  end

  def data_size
    s = "bytes: #{data.size}"
    s << ", image: #{content.image_size[:width]}x#{content.image_size[:height]}" if is_image?
    s
  end

  def data_text_lines
    (x = data) && ! is_binary? ? x.count("\n") : 0
  end

  def data_text
    data
  end

  def data_text= x
    self.data = x
  end

  def forced_window_link(text, opts)
    %Q{<a href="#{opts[:uri]}" title="#{opts[:title]}" target="#{opts[:target]}" onclick="window.open(this.href, '#{opts[:target]}', 'left=10, top=10, height=400, width=800, menubar=1, location=1, toolbar=1, scrollbars=1, status=1, resizable=1'); return false;">#{text}</a>}
  end

  def preview_link(text = 'P')
    forced_window_link(text, :uri => preview_uri, :title => 'Preview ...', :target => 'contenter_preview')
  end

  def preview_uri
    case self
    when Content
      controller = :contents
      x = uuid || copy_from_uuid
    when Content::Version
      controller = :content_versions
      x = id
    end
    "/#{controller}/#{content_preview_action}/#{x}"
  end

  def actual_link(text = 'A')
    forced_window_link(text, :uri => actual_uri, :title => 'Actual ...', :target => 'contenter_actual')
  end

  def content_preview_action
    :data
  end

end
