module RoleAdditions
  def streamlined_name *args
    name
  end
end
Role.class_eval { include RoleAdditions }

Streamlined.ui_for(Role) do
  default_order_options :order => 'name'

  uc =
    [
     :name, {
       :link_to => { :action => 'show' }
     },
     :description
    ]
  user_columns *uc

  sc = 
    [
     :name, {
       :link_to => { :action => 'edit' }
     },
     :description
    ]
 
  sc +=
    [ 
     :created_at,
     :updated_at
    ]
  show_columns *sc

end



