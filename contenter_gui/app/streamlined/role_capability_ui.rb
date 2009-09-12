module RoleCapabilityAdditions
  def streamlined_name *args
    "#{role.name} #{capability.name}"
  end

  def capability_allow_string
    (capability ? capability.name : "<<NOT-DEFINED>>") + " => #{allow.inspect}"
  end

end
RoleCapability.class_eval { include RoleCapabilityAdditions }

Streamlined.ui_for(RoleCapability) do
  default_order_options :order => '(select name from roles where id = role_id), (select name from capabilities where id = capability_id)'
  table_filter false

  uc =
    [
     :role, {
       :edit_in_list => false,
       :link_to => { :action => 'show' }
     },
     :capability, {
       :edit_in_list => false,
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
       :show_view =>
       [
        :link, 
        { :controller => :roles, :action => :show },
       ],
     },
     :capability, {
       :show_view =>
       [
        :link,
        { :controller => :capabilities, :action => :show },
       ],
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


