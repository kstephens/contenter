module UserAdditions
  def streamlined_name *args
    login
  end

  def should_display_column_in_context? col, view
    # $stderr.puts " **** should_display_column_in_context? #{col.inspect}, #{view}"
    controller = ApplicationController.current
    cu = u = cntx = nil
    view.instance_eval do
      cu = current_user
      u = _user
      cntx = crud_context
    end

    # $stderr.puts "   cu = #{cu && cu.name}"
    # $stderr.puts "   u  = #{u && u.name}"
    # $stderr.puts "   cntx = #{cntx.inspect}"

    result = false
    result ||= cntx != :edit
    result ||= (cu && cu.has_capability?("controller/users/*"))
    result ||=
      case cn = col.name.to_s
      when 'login', 'roles'
        (cu && cu.has_capability?("controller/users/edit/#{cn}"))
      when 'name', 'email', 'password', 'password_confirmation'
        (cu && u && cu.id == u.id) ||
        (cu && cu.has_capability?("controller/users/edit/#{cn}"))
      else
        true
      end

    # $stderr.puts "     => #{result.inspect}"
    result
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
     :roles, {
       :edit_in_list => false,
       :link_to => { :action => 'show' }
     }
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
    ]
 
  sc +=
    [ 
     :created_at,
     :updated_at
    ]

  sc +=
    [
     :roles, {
       :show_view =>
       [
        :list, { 
          :fields => [ :name ],
          :link_to => { :controller => :roles, :action => :show },
        },
       ],
     },
    ]
  show_columns *sc


  ec = [ ]
  ec += 
    [
     :login,
     :name,
     :email,
     :password,
     :password_confirmation,
    ]

  ec +=
    [
     :roles,
    ]
 
  edit_columns *ec

end



