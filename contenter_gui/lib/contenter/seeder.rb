module Contenter
  # Defines the tasks necessary to seed the contenter database to a usable state.
  class Seeder
    
    attr_accessor :role_capability, :users, :user_roles
    attr_accessor :all_actions

    def self.all_actions
      @@all_actions ||=
        [
         :core_users!,
         :core_roles!,
         :core_user_roles!,
         :core_mime_types!,
         :core_countries_brands_apps!,
         :core_languages!,
         :core_content_types!,
         :core_content_status!,
         :core_vls!,
         ]
    end

    def initialize opts = { }
      @all_actions ||= self.class.all_actions.dup

      @role_capability =
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
         
         [ 'auth_admin',
           'Can adminster users, roles and capabilities.',
           [ 
            'controller/users/*',
            'controller/roles/*',
            'controller/capabilities/*',
            'controller/role_capabilities/*'
           ],
         ],

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
            'controller/version_lists/*',
            'controller/version_lists_names/*',
           ],
         ],

         [ 'content_editor',
           'Can only edit existing content.',
           [
            'controller/contents/data',
            'controller/contents/edit',
            'controller/contents/update',
            'controller/api/search',
            'controller/api/dump',
           ],
         ],
         
         [ 'content_creator',
           'Can create new content.',
           [
            'controller/contents/new',
            'controller/contents/create',
            'controller/api/search',
            'controller/api/dump',
           ],
         ],

         [ 'content_developer',
           'Can create new content and content keys.',
           [
            'controller/contents/*',
            'controller/content_keys/*',
            'controller/api/*',
           ],
         ],

         [ 'content_releaser',
           'Can create and modify Version List Names.',
           [
            'controller/version_list_names/*',
           ],
         ],

        ]

      @users = 
        [ 
         'root',
         '__test__',
         '__default__',
         '__content_editor__',
         '__content_creator__',
         '__content_developer__',
         '__content_admin__',
        ]

      @user_roles = {
        'root' => 
        [ 
         'superuser',
        ],

        '__test__' =>
        [
         'superuser',
        ],

        '__default__' =>
        [ 
         '__default__',
        ],

        '__content_editor__' => 
        [ 
         '__default__', 
         'content_editor',
        ],

        '__content_creator__' =>
        [
         '__default__',
         'content_editor',
         'content_creator',
        ],

        '__content_developer__' =>
        [
         '__default__',
         'content_editor',
         'content_creator',
         'content_developer',
        ],

        '__content_admin__' =>
        [
         '__default__',
         'content_admin',
        ],
      }

      opts.each do | k, v |
        s = "#{k}="
        send(s, v) if respond_to? s
      end

      instance_eval { yield } if block_given?
    end


    # invokes every other creation method explicitly (implicity is the devil!)
    def all!
      return self if already_seeded?
      $stderr.puts "  all:"
      User.transaction do
        all_actions.each do | action |
          action! action
        end
      end
      self
    end


    # Call this method to invoke a particular seed action method.
    # DO NOT CALL THE SEED ACTION METHOD DIRECTLY.
    def action! action
      User.transaction do
        $stderr.puts "  #{action}:"
        send(action)
      end
    end


    ### following are the methods to do individual tasks for seed data creation ###

    # Returns true if database is already seeded.
    def already_seeded?
      ! ! User[users.first] 
    end


    def core_users!
      users.each do | name |
        login = name
        password = name + name
        password = password[0 .. 39]
        $stderr.puts "  User: #{login.inspect}"
        user = User.create!(:login => login,
                            :name => name,
                            :email => "admin+#{name.gsub('_', '-')}@localhost.com",
                            :password => password,
                            :password_confirmation => password
                            )
        
        $stderr.puts "     password: #{password.inspect}"
      end
    end
    
    def core_roles!
      Role.build_role_capability *@role_capability
    end

    def core_user_roles!
      @user_roles.each do | user, roles |
        Role.build_user_role user, *roles
      end
    end

    # Creates statuses!
    def core_content_status!
      UserTracking.current_user = 'root'
      [
       [ 'initial',  'Initial state' ],
       [ 'created',  'Newly created' ],
       [ 'modified', 'Recently modified' ],
       [ 'approved', 'Approved for testing' ],
       [ 'released', 'Released for production' ],
      ].each do | r |
        ContentStatus.create!({
                                :code => r[0],
                                :name => r[0],
                                :description => r[1] || '',
                              })
      end
    end

    # Creates standard content types.
    def core_content_types!
      [
       [ 'phrase',   'phrase',   'Localized short phrases' ],
       [ 'email',    'email',    'Localized email templates' ],
       [ 'faq',      'faq',      'Localized frequently asked questions' ],
       [ 'contract', 'contract', 'Localized contract template', /\A[-a-z0-9_]+(\/[-a-z0-9_]+)*\Z/i ],
       [ 'image',    'image',    'Graphic image' ],
       [ 'sound',    'sound',    'Sound' ],
      ].each do | r |
        ContentType.create!(:code => r[0], 
                            :name => r[1],
                            :description => r[2] || '',
                            :key_regexp => (r[3] || /\A.+\Z/).inspect
                            )
      end
    end

    def core_mime_types!
      [
       [ '_',            'Any',          'Wildcard Mime Type' ],
       [ 'text/plain',   'text/plain',   'Plain ASCII Text' ],
       [ 'text/html',    'text/html',    'HTML Text' ],
      ].each do | r |
        MimeType.create!(:code => r[0], 
                         :name => r[1],
                         :description => r[2] || ''
                         )
      end
    end

    def core_countries_brands_apps!

      ##### countries ####
      [
       [ '_',  'Any Country', 'Wildcard' ],
       [ 'US', 'United States of America' ],
       [ 'GB', 'Great Britain' ],
       [ 'AU', 'Australia' ],
       [ 'CA', 'Canada' ],
      ].each do | r |
        Country.
          create!(:code => r[0], 
                  :name => r[1], 
                  :description => r[2] || '')
      end

      ##### brands ####
      [
       [ '_',   'Any Brand',     'Wildcard Brand' ],
       [ 'test', 'Test Brand',  'For testing' ],
      ].each do | r |
        Brand.
          create!(:code => r[0], 
                  :name => r[1], 
                  :description => r[2] || '')
      end

      ##### apps ####
      [
       [ '_',      'Any Application', 'Wildcard' ],
       [ 'test',   'Test Application', 'For testing' ],
      ].each do | r |
        Application.
          create!(:code => r[0], 
                  :name => r[1], 
                  :description => r[2] || '')
      end

    end

    def core_languages!
      [
       [ '_', 'Any Language', 'Any Language' ],
       [ 'en', 'English' ],
       [ 'es', 'Spanish' ],
       [ 'fr', 'French' ],
      ].each do | r |
        Language.
          create!(:code => r[0],
                  :name => r[1], 
                  :description => r[2] || ''
                  )
      end
    end

    def core_vls!
      VersionList.create(:comment => 'Default version list')
    end

    # Creates standard version list names - deprecated
    def core_vlns!
      rln = [
             :production,
             :development,
             :integration,
            ]

      UserTracking.current_user = 'root'

      # Create some VLNs.
      rln.each do | n |
        $stderr.puts "  VersionListName: #{n.to_s.inspect}"
        VersionListName.create!(:name => n.to_s, :description => '', :version_list => VersionList.first)
      end
    end
  end
end
