module RoleAdditions
  def streamlined_name *args
    name
  end

  def should_display_column_in_context? col, view
    $stderr.puts " **** should_display_column_in_context? #{self.class.name} #{col.inspect}, #{view}"
    controller = ApplicationController.current
    cu = cntx = nil
    view.instance_eval do
      cu = current_user
      cntx = crud_context
    end

    $stderr.puts "   cu = #{cu && cu.name}"
    $stderr.puts "   cntx = #{cntx.inspect}"

    result = false
    result ||= cntx != :edit
    result ||= (cu && cu.has_capability?("controller/roles/*"))
    result ||=
      case cn = col.name.to_s
      when 'users', 'role_capabilities'
        (cu && cu.has_capability?("controller/roles/edit/#{cn}"))
      else
        true
      end

    $stderr.puts "     => #{result.inspect}"
    result
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
     :description,
     :users, {
       :edit_in_list => false,
       :link_to => { :action => 'show' }
     },
     :role_capabilities, {
       :edit_in_list => false,
       :link_to => { :action => 'show' }
     },

    ]
   user_columns *uc
  
  sc = uc

  sc +=
    [ 
     :created_at,
     :updated_at,
    ]

  sc +=
    [
     :users, {
       :show_view =>
       [
        :list, { 
          :fields => [ :name ],
          :link_to => { :controller => :users, :action => :show },
        },
       ],
     },
     :role_capabilities, {
       :show_view =>
       [
        :list, { 
          :fields => [ :capability_allow_string ],
          :link_to => { :controller => :role_capabilities, :action => :show },
        },
       ],
     },
    ]

  show_columns *sc

end



