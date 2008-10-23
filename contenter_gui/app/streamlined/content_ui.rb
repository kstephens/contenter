module ContentAdditions
  def streamlined_name *args
    code
  end

  def content_short max_size = 16
    x = content
    x =~ /\A[\n\r]*([^\n\r]*)[\n\r]/
    x = $1 || x
    if x != content || content.size > max_size
      x = x[0 .. max_size] + '...'
    end
    x
  end

  def content_formatted
    "<pre>#{ERB::Util.h content}</pre>"
  end
end
Content.class_eval { include ContentAdditions }

Streamlined.ui_for(Content) do
  default_order_options :order => "key, " +
    [ :language, :country, :brand, :application ].
    map { | x |
      x = x.to_s
      xs = x.pluralize
      "(select #{xs}.code from #{xs} where #{xs}.id = #{x}_id)"
    }.join(', ')

  def self._list_field name
    human_name = name.to_s.humanize
    {
      :human_name => human_name,
      :edit_in_list => false,
      #:link_to => { 
      #  :controller => name.to_s.pluralize, 
      #  :action => 'show'
      #},
      :show_view => [ :link,
                      {
                        :fields => [ :code ],
                        :editable => false,
                      }
                    ],
    }
  end

  def self._show_field name
    human_name = name.to_s.humanize
    {
      :human_name => human_name,
      :show_view => [ :link, 
                      {
                        :fields => [ :code ],
                      }
                    ],
    }
  end

  list_columns \
  :key, { 
    :link_to => { :action => 'show' },
  },
  :content_type, _list_field(:content_type),
  :language,     _list_field(:language),
  :country,      _list_field(:country),
  :brand,        _list_field(:brand),
  :application,  _list_field(:application),
  :content_short, { 
    :human_name => 'Content',
    :link_to => { :action => 'show' },
  }
  
  show_columns \
  :key, { 
    :link_to => { :action => 'edit' },
  },
  :content_type, _show_field(:content_type),
  :language,     _show_field(:language),
  :country,      _show_field(:country),
  :brand,        _show_field(:brand),
  :application,  _show_field(:application),
  :created_at,
  :updated_at,
    :content_formatted, {
    :human_name => 'Content',
    :allow_html => true,
    # :link_to => { :action => 'edit' },
  }
  
  edit_columns \
  :key,
  :content_type,
  :language,
  :country,
  :brand,
  :application,
  :content

end

