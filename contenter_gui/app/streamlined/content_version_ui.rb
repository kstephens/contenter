
Streamlined.ui_for(ContentVersion) do
  def self._list_field name, human_name = nil
    human_name ||= name.to_s.humanize
    {
      :human_name => human_name,
      :edit_in_list => false,
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


  default_order_options :order => Content.order_by


  ####################################################################


  list_columns \
  :content_key,  _list_field(:content_key, 'Key').
    update(:link_to => { 
               :controller => 'contents', 
               :action => 'show',
             }),
  :content_type_code, { 
    :human_name => 'Type',
  },
  :language,     _list_field(:language),
  :country,      _list_field(:country),
  :brand,        _list_field(:brand),
  :application,  _list_field(:application),
  :mime_type,    _list_field(:mime_type),
  :version,
  :data_short, { 
    :human_name => 'Data',
    :link_to => { :action => 'show' },
  }
  
  show_columns \
  :uuid,
  :version,
  :content_type_code, { 
    :human_name => 'Type',
  },
  :content_key,  _show_field(:content_key, 'Key'),
  :language,     _show_field(:language),
  :country,      _show_field(:country),
  :brand,        _show_field(:brand),
  :application,  _show_field(:application),
  :mime_type,    _show_field(:mime_type),
  :creator, {
    :show_view => 
    [
     :link, { 
       :controller => :users,
       :action => 'show',
     },
    ],
  },
  :created_at,
  :updater, {
    :show_view =>
    [
     :link, { 
       :controller => :users,
       :action => 'show',
     },
    ],
  },
  :updated_at,
  :md5sum,
  :data_formatted, {
    :human_name => 'Data',
    :allow_html => true,
    # :link_to => { :action => 'edit' },
  }
  
  edit_columns \
  :content_key,
  :language,
  :country,
  :brand,
  :application,
  :mime_type,
  :data

end

