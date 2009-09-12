Streamlined.ui_for(ContentKey) do
  default_order_options :order => "code"

  quick_delete_button false
  new_submit_button :ajax => false

  user_columns \
  :code, {
    :link_to => { :action => 'show' }
  },
  :content_type, {
    :human_name => 'Type',
    :edit_in_list => false,
  },
  :name,
  :description,
  :version, {
    :read_only => true,
    :filterable => false
  }
  
  show_columns \
  :uuid,
  :version,
  :code, {
    :link_to => { :action => 'edit' }
  },
  :content_type, {
    :human_name => 'Type',
    :show_view => 
    [
     :link,
     {
       :fields => [ :code ],
     },
    ],
    # :link_to => { :controller => :content_types, :action => 'show' },
  },
  :name,
  :description,
  :created_at,
  :updated_at
  
  footer_partials :show => 'shared/related'
end

