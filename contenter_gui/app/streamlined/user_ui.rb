module UserAdditions
  def streamlined_name *args
    login
  end
end
User.class_eval { include UserAdditions }

Streamlined.ui_for(User) do
  default_order_options :order => "login"

  uc =
    [
     :login, { 
       :link_to => { :action => 'show' }
     },
     :name, {
       :link_to => { :action => 'show' }
     },
     :email,
    ]
  user_columns *uc

  sc = 
    [
     :login, {
       :link_to => { :action => 'edit' }
     },
     :name, {
       :link_to => { :action => 'edit' }
     },
     :email,
     :password,
     :password_confirmation,
    ]
 
  sc +=
    [ 
     :created_at,
     :updated_at
    ]
  show_columns *sc

end



