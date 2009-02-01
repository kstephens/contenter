module ContentKeyAdditions
  def streamlined_name *args
    code
  end
end
ContentKey.class_eval { include ContentKeyAdditions }

Streamlined.ui_for(ContentKey) do
  default_order_options :order => "code"

  user_columns \
  :code, {
    :link_to => { :action => 'show' }
  },
  :content_type, {
    :human_name => 'Type',
    :edit_in_list => false,
  },
  :name,
  :description
  
  show_columns \
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

