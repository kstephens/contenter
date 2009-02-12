class CreateDefaultRoles < ActiveRecord::Migration
  @@role_capability =
    [
     [ '__default__',
       'Unauthorized user and basic permissions',
       {
         'controller/users/list' => true,
         'controller/users/show' => true,
         'controller/users/+' => false,
         'controller/roles/list' => true,
         'controller/roles/show' => true,
         'controller/roles/+' => false,
         'controller/capabilities/*' => false,
         'controller/role_capabilities/*' => false,
         'controller/api/*' => false,
         'controller/+/index' => true,
         'controller/+/list' => true,
         'controller/+/show' => true,
         'controller/+/search' => true,
       },
     ],

     [ 'superuser',
       'Can do everything.',
       [
        'controller/*/*',
       ],
     ],

     [ 'user_admin',
       'Can adminster users, roles and capabilities',
       [ 
        'controller/users/*',
        'controller/roles/*',
        'controller/capabilities/*',
        'controller/role_capabilities/*'
       ],
     ],

=begin
     [ 'content_user',
       'Can list and show content objects.',
       [
        'controller/contents/list',
        'controller/contents/show',
        'controller/contents/search',
        'controller/content_versions/list',
        'controller/content_versions/show',
        'controller/content_types/list',
        'controller/content_types/show',
        'controller/content_keys/list',
        'controller/content_keys/show',
        'controller/languages/list',
        'controller/languages/show',
        'controller/countries/list',
        'controller/countries/show',
        'controller/brands/list',
        'controller/brands/show',
        'controller/applications/list',
        'controller/applications/show',
        'controller/mime_types/list',
        'controller/mime_types/show',
        'controller/api/search',
        'controller/api/dump',
       ],
     ],
=end

     [ 'content_admin',
       'Can do everything to content objects.',
       [
        'controller/contents/*',
        'controller/content_versions/*',
        'controller/content_types/*',
        'controller/content_keys/*',
        'controller/languages/*',
        'controller/countries/*',
        'controller/brands/*',
        'controller/applications/*',
        'controller/mime_types/*',
        'controller/api/*',
        'controller/revision_lists/*',
        'controller/revision_lists_names/*',
       ],
     ],

     [ 'content_editor',
       'Can only edit existing content.',
       [
        'controller/contents/data',
        'controller/contents/edit',
        'controller/contents/update',
        'controller/content_versions/revert',
        'controller/api/*',
       ],
     ],
     
     [ 'content_creator',
       'Can create new content and content keys.',
       [
        'controller/contents/new',
        'controller/contents/create',
        'controller/contents/edit_as_new',
        'controller/content_keys/new',
        'controller/content_keys/create',
        'controller/content_keys/edit_as_new',
        'controller/api/*',
       ],
     ],

     [ 'content_releaser',
       'Can create and modify Revision List Names.',
       [
        'controller/revision_list_names/*',
       ],
     ],

    ]

  def self.up
    Role.build_role_capability *@@role_capability

    Role.build_user_role 'root', 'superuser'
    Role.build_user_role '__default__', '__default__'
    Role.build_user_role '__content_editor__', '__default__', 'content_editor'
    Role.build_user_role '__content_creator__', '__default__', 'content_editor', 'content_creator'
    Role.build_user_role '__content_admin__', '__default__', 'content_admin'
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
