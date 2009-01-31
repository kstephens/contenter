module RoleCapabilityAdditions
  def streamlined_name *args
    "#{role.name} #{capability.name}"
  end
end
Role.class_eval { include RoleCapabilityAdditions }

Streamlined.ui_for(RoleCapability) do
  default_order_options :order => '(select name from roles where id = role_id) DESC, (select name from capabilities where id = capability_id) DESC'
  
  uc =
    [
     :role, {
       :link_to => { :action => 'show' }
     },
     :capability, {
       :link_to => { :action => 'show' }
     },
     :allow, {
       :edit_in_list => true,
     },
    ]
  user_columns *uc

  sc = 
    [
     :role, {
       :link_to => { :action => 'edit' }
     },
     :capability, {
       :link_to => { :action => 'edit' }
     },
     :allow,
    ]
 
  sc +=
    [ 
     :created_at,
     :updated_at
    ]
  show_columns *sc

end


