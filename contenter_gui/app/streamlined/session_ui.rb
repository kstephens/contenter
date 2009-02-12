SessionAdmin = Session

module SessionAdminAdditions
  def streamlined_name *args
    session_id
  end
  def session
    session_id.to_s
  end
end
SessionAdmin.class_eval { include SessionAdminAdditions }

Streamlined.ui_for(SessionAdmin) do
  default_order_options :order => "created_at DESC"

  c =
    [
     :session, { 
       :link_to => { :action => 'show' }
     },
     :user, {
       :edit_in_list => false,
       :show_view =>
       [
        :link, { :controller => :users, :action => :show },
       ]
     }, 
    ]
  c +=
    [ 
     :created_at,
     :updated_at
    ]

  list_columns *c


  sc = 
    [
     :session, { 
       :link_to => { :action => 'show' }
     },
     :user,
    ]
 
  sc +=
    [ 
     :created_at,
     :updated_at
    ]
  show_columns *sc


  edit_columns :user
end



