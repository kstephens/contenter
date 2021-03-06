
Streamlined.ui_for(Content) do
  extend UserTrackingUiHelper

  quick_delete_button false

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
  :content_status,  _list_field(:content_status),
  :filename, #  _list_field(:filename),
  :preview_link, {
    :human_name => '',
    :allow_html => true,
  },
  :data_short, { 
    :human_name => 'Data',
    :link_to => { :action => 'show' },
    :allow_html => true,
  }
  
  c = 
    [
     :uuid, {
#       :show_view =>
#       [ :link, 
#         {
#           :fields => [ :uuid ],
#           :link_to => { :action => :show, :id => :uuid },
#         }
#       ],
     },
     :version,
     :content_type_code, { 
       :human_name => 'Type',
       # FIXME:
       # :link_to => { :controller => :content_types, :action => :show }
     },
     :content_key,  _show_field(:content_key, 'Key'),
     :language,     _show_field(:language),
     :country,      _show_field(:country),
     :brand,        _show_field(:brand),
     :application,  _show_field(:application),
     :mime_type,    _show_field(:mime_type),
     :content_status,  _show_field(:content_status),
    ]
  c += show_columns_user_tracking
  c += 
    [
     :filename,
     :md5sum,
     :data_size,
     :data_formatted, {
       :human_name => 'Data',
       :allow_html => true,
       # :link_to => { :action => 'edit' },
     }
    ]
  show_columns *c
  
  edit_columns \
  :content_key,
  :language,
  :country,
  :brand,
  :application,
  :mime_type,
  :filename,
  :data

  footer_partials :show => 'contents/versions'

end

