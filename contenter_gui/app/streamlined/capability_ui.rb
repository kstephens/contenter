module CapabilityAdditions
  def streamlined_name *args
    name
  end
end
Capability.class_eval { include CapabilityAdditions }

Streamlined.ui_for(Capability) do
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
     :updated_at,
     :role_capabilities, {
       :show_view =>
       [
        :list, { 
          :fields => [ :to_s ],
          :link_to => { :controller => :role_capabilities, :action => :show },
        },
       ],
     }
    ]
  show_columns *sc

end



