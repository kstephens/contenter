module ContentAdditions
  def streamlined_name *args
    content_key.code
  end

  def content_short max_size = 16
    x = content
    x =~ /\A[\n\r]*([^\n\r]*)[\n\r]/
    x = $1 || x
    if x != content || content.size > max_size
      # Handle UTF-8: do not truncate in the middle of a UTF-8 sequence.
      while max_size < content.size && x[max_size] > 127
        max_size += 1
      end

      x = x[0 .. max_size] + '...'
    end
    x
  end

  def content_type_code
    content_key.content_type.code
  end

  def content_type_code= x
    @content_type = ContentType[x]
  end

  def content_key_code
    content_key.code
  end

  def content_key_code= x
    @content_key_code = x
  end

  def content_formatted
    "<pre>#{ERB::Util.h content}</pre>"
  end

  def content_text
    content
  end

  def content_text= x
    self.content = x
  end
end
Content.class_eval { include ContentAdditions }

Streamlined.ui_for(Content) do
  def self._list_field name, human_name = nil
    human_name ||= name.to_s.humanize
    {
      :human_name => human_name,
      :edit_in_list => false,
=begin
      :link_to => { 
        :controller => name.to_s.pluralize, 
        :action => 'show'
      },
=end
=begin
      :show_view => 
      [ :link,
        {
          :fields => [ :code ],
          :editable => false,
        }
      ],
=end
    }
  end

  def self._show_field name, human_name = nil
    human_name ||= name.to_s.humanize
    {
      :human_name => human_name,
      :show_view =>
      [ :link, 
        {
          :fields => [ :code ],
        }
      ],
    }
  end


  ####################################################################


  default_order_options :order => 
    [ :content_key, :language, :country, :brand, :application ].
    map { | x |
      x = x.to_s
      xs = x.pluralize
      "(SELECT #{xs}.code FROM #{xs} WHERE #{xs}.id = #{x}_id)"
    }.join(', ')

  ####################################################################


  list_columns \
  :content_key,  _list_field(:content_key, 'Key'),
  :content_type_code, { 
    :human_name => 'Type',
  },
  :language,     _list_field(:language),
  :country,      _list_field(:country),
  :brand,        _list_field(:brand),
  :application,  _list_field(:application),
  :mime_type,    _list_field(:mime_type),
  :content_short, { 
    :human_name => 'Content',
    :link_to => { :action => 'show' },
  }
  
  show_columns \
  :content_key,  _show_field(:content_key, 'Key'),
  :content_type_code, { 
    :human_name => 'Type',
  },
  :language,     _show_field(:language),
  :country,      _show_field(:country),
  :brand,        _show_field(:brand),
  :application,  _show_field(:application),
  :mime_type,    _show_field(:mime_type),
  :created_at,
  :updated_at,
  :content_formatted, {
    :human_name => 'Content',
    :allow_html => true,
    # :link_to => { :action => 'edit' },
  }
  
  edit_columns \
  :content_type_code, {
    :human_name => 'Type',
    # :enumeration => ContentType.find(:all),
  },
  :content_key_code, {
    :human_name => 'Key',
    :allow_html => true,
  },
  :language,
  :country,
  :brand,
  :application,
  :mime_type,
  :content_text, {
    :human_name => 'Content',
    :allow_html => true,
  }

end

