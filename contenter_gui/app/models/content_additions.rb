module ContentAdditions
  ####################################################################
  # View/Controller helpers
  #

  def version_as_html
    x = version.to_s
    x
  end

  def content_type
    @content_type ||
    ((x = content_key) &&
      x.content_type
     )
  end

  def content_type_id
    (x = content_type) &&
      x.id
  end

  def content_type_id= x
    @content_type = ContentType[x.to_i]
  end

  def content_type_code
    (x = content_type) &&
      x.code
  end

  def content_type_code= x
    @content_type = ContentType[x.to_s]
  end

  def content_key_code
    (x = content_key) &&
      x.code
  end

  def content_key_code= x
    @content_key_code = x
  end


  ####################################################################
  # Streamline support
  #

  def streamlined_name *args
    content_key.code
  end

  
  def data_short max_size = 32
    plugin # force mixin # FIXME use some callback like after_find?
    x = data_for_list || ''
    x =~ /\A[\n\r]*([^\n\r]*)[\n\r]/
    x = $1 || x
    if x != data || data.size > max_size
      # Handle UTF-8: do not truncate in the middle of a UTF-8 sequence.
      while max_size < data.size && (c = x[max_size]) && c > 127
        max_size += 1
      end

      x = x[0 .. max_size] + '...'
    end
    x
  end

  def data_formatted
    "<pre>#{ERB::Util.h(data || '')}</pre>"
  end

  def data_text_lines
    (x = data) ? x.count("\n") : 0
  end

  def data_text
    data
  end

  def data_text= x
    self.data = x
  end
end
