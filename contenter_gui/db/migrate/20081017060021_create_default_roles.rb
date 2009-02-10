class CreateDefaultRoles < ActiveRecord::Migration
  @@role_capability =
    [
     [ '__default__',
       {
        'controller/roles/*' => false,
        'controller/capabilities/*' => false,
        'controller/roles_capabilities/*' => false,
        'controller/users/list' => false,
        'controller/users/+' => false,
        'controller/roles/*' => false,
        'controller/role_capabilities/*' => false,
        'controller/api/*' => false,
        'controller/+/index' => true,
        'controller/+/list' => true,
        'controller/+/show' => true,
        'controller/+/search' => true,
       },
     ],

     [ 'superuser', 
       [
        'controller/*/*',
       ],
     ],

     [ 'user_admin',
       [ 
        'controller/users/*',
       ],
     ],

     [ 'content_admin',
       [
        'controller/content_versions/*',
        'controller/content_types/*',
        'controller/languages/*',
        'controller/countries/*',
        'controller/brands/*',
        'controller/applications/*',
        'controller/mime_types/*',
       ],
     ],

     [ 'content_editor',
       [
        'controller/contents/edit',
        'controller/contents/update',
        'controller/content_versions/revert',
        'controller/api/*',
       ],
     ],
     
     [ 'content_creator',
       [
        'controller/contents/new',
        'controller/contents/create',
        'controller/contents/edit_as_new',
        'controller/content_keys/new',
        'controller/content_keys/create',
        'controller/content_keys/edit_as_new',
       ],
     ],
    ]

  def self.up
    user = User.find(:first, :conditions => { :login => 'root' }) || raise("Cannot find root user")
    role = Role.create!(:name => 'superuser', :description => 'Able to do everything.')
    user.roles << role

    user = User.find(:first, :conditions => { :login => '__default__' }) || raise("Cannot find __default__ user")
    role = Role.create!(:name => '__default__', :description => 'Minimal permissions.')
    user.roles << role

    @@role_capability.each do | (role, caps) |
      $stderr.puts "  Role: #{role.inspect}"
      role = 
        Role.find(:first, :conditions => { :name => role }) || 
        Role.create!(:name => role, :description => role)
      if Array === caps
        caps = caps.inject({ }) { | h, cap | h[cap] = true; h }
      end
      caps.each do | cap, allow |
        $stderr.puts "    Capability: #{cap.inspect} => #{allow.inspect}"
        cap = 
          Capability.find(:first, :conditions => { :name => cap } ) || 
          Capability.create!(:name => cap, :description => cap)
        role_cap = RoleCapability.create!(:role => role, :capability => cap, :allow => allow)
      end
    end
  end

  def self.down
    @@role_capability.each do | (role, caps) |
      role = Role.find(:first, :name => role)
      if caps == Array
        caps = caps.inject({ }) { | h, cap | h[cap] = true; h }
      end
      role.role_capabilities.each do | rc |
        rc.destroy
      end
      caps.each do | cap, allow |
        cap = Capability.find(:first, :name => cap)
        cap.destroy
      end
      role.destroy
    end

  end
end
