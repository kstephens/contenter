# Defines the tasks necessary to seed the contenter database to a usable state.
class Seeder
  attr_accessor :role_capability, :users, :user_roles

  def initialize
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

  end


  # invokes every other creation method explicitly (implicity is the devil!)
  def create_all
    return self if already_seeded?
    $stderr.puts "  create_all"
    User.transaction do
      create_users
      create_roles
      create_user_roles
      create_mime_types
      create_countries_brands_apps
      create_languages
      create_content_types
      create_vlns
    end
    self
  end


  ### following are the methods to do individual tasks for seed data creation ###

  # Returns true if database is already seeded.
  def already_seeded?
    ! ! User[@users.first] 
  end


  def create_users
    @users.each do | name |
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
  
  def create_roles
    Role.build_role_capability *@role_capability
  end

  def create_user_roles
    @user_roles.each do | user, roles |
      Role.build_user_role user, *roles
    end
  end

  # Creates standard content types.
  def create_content_types
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

  def create_mime_types
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

  def create_countries_brands_apps

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
     [ 'US',  'CNU US Brand', 'cashnetusa.com' ],
     [ 'GB',  'CNU GB Brand', 'quickquid.co.uk' ],
     [ 'AEA', 'Advance America US JV Brand', 'applyadvanceamerica.com' ],
     [ 'AU',  'CNU AU Brand', 'dollarsdirect.com.au' ],
     [ 'CA',  'CNU CA Brand', 'TBD' ],
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
     [ 'cnuapp', 'CashNetUSA Main App', 'CNUAPP for CNU' ],
    ].each do | r |
      Application.
        create!(:code => r[0], 
                :name => r[1], 
                :description => r[2] || '')
    end

  end

  def create_languages
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

  # Creates standard version list names.
  def create_vlns
    rln = [
           :production,
           :development,
           :integration,
          ]

    UserTracking.current_user = 'root'

    api = Content::API.new(:log => $stderr)
    # Create some VLNs.
    rln.each do | n |
      $stderr.puts "  VersionListName: #{n.to_s.inspect}"
      VersionListName.create!(:name => n.to_s, :description => '', :version_list => api.version_list)
    end
  end
end
