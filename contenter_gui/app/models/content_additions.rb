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

  def data_short max_size = nil, data_for_list = nil
    plugin # force mixin # FIXME use some callback like after_find?
    max_size ||= 32
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
