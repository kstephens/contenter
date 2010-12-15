module Contenter
    
  # Defines the tasks necessary to seed the contenter database to a usable state.
  class Seeder

    # Seed data arrays.
    attr_accessor :role_capability, :users, :user_roles
    attr_accessor :content_types, :content_statuses
    attr_accessor :languages, :countries, :brands, :applications, :mime_types
    attr_accessor :version_list_names

    # List of actions to perform.
    attr_accessor :all_actions

    def self.all_actions
      @@all_actions ||=
        [
         :core_users!,
         :core_roles!,
         :core_user_roles!,
         :core_mime_types!,
         :core_languages!,
         :core_countries!,
         :core_brands!,
         :core_applications!,
         :core_content_types!,
         :core_content_status!,
         :core_vls!,
         ]
    end

    # Initialize seed data.
    def data_default!
      @role_capability =
        [
         [ '__default__',
           'Unauthorized user and basic permissions',
           {
             'controller/users/{list,show}' => true,
             'controller/users/+' => false,
             'controller/roles/{list,show}' => true,
             'controller/roles/+' => false,
             'controller/capabilities/*' => false,
             'controller/role_capabilities/*' => false,
             'controller/api/*' => false,
             'controller/contents/{yaml,data,mime_type,same}' => true,
             'controller/+/{index,list,show,search,preview}' => true,
             'controller/sessions/become_real_user' => true,
           },
         ],
         
         [ 'superuser',
           'Can do everything.',
           [
            'controller/*/*{,?*=*}',
            'controller/*/*/*{,?*=*}', # for workflow.
           ],
         ],

         [ 'become_any_user',
           "Can become any user.",
           [
            'controller/sessions/become_user{,?login=*}',
            'controller/sessions/become_real_user',
           ],
         ],
         
         [ 'auth_admin',
           'Can adminster users, roles and capabilities.',
           [ 
            'controller/users/*',
            'controller/users/edit/*',
            'controller/roles/*',
            'controller/roles/edit/*',
            'controller/capabilities/*',
            'controller/role_capabilities/*'
           ],
         ],

         [ 'content_admin',
           'Can do everything to content objects.',
           [
            'controller/{contents,content_versions,content_keys,content_types}/*{,?*=*}',
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

         [ 'content_destroyer',
           'Can destroy existing content.',
           [
            'controller/contents/{destroy}{,?content_type=+}',
            ],
         ],
 
         [ 'content_editor',
           'Can only edit existing content.',
           [
            'controller/contents/{data,edit,update}{,?content_type=+}',
            'controller/api/{search,dump}',
           ],
         ],
         
         [ 'content_creator',
           'Can create new content.',
           [
            'controller/contents/{new,create}{,?content_type=+}',
            'controller/api/{search,dump}',
           ],
         ],

         [ 'content_developer',
           'Can create new content and content keys.',
           [
            'controller/{contents,content_keys}/*{,?content_type=+}',
            'controller/api/*',
            'controller/workflow/list/*{,?content_type=+}',
            'controller/workflow/perform_status_action/approve{,?content_type=+,?brand=+}', # ?!?!?!
           ],
         ],

         [ 'content_approver',
           'Can move content into the approved state, for moving to contenter_integration files.',
           [
            'controller/workflow/list{,?content_type=+}',
            'controller/workflow/perform_status_action{,?content_type=+}',
            'controller/workflow/perform_status_action/approve{,?content_type=+,?brand=+}',
           ],
         ],

         [ 'content_releaser',
           'Can move content into the released state, for moving to contenter_production files.',
           [
            'controller/workflow/list{,?content_type=+}',
            'controller/workflow/perform_status_action{,?content_type=+}',
            'controller/workflow/perform_status_action/release{,?content_type=+,?brand=+}',
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
         '__content_approver__',
         '__content_releaser__',
         '__content_admin__',
        ]

      @user_roles = {
        'root' => 
        [ 
         'superuser',
         'become_any_user',
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

        '__content_approver__' => 
        [ 
         '__default__', 
         'content_approver',
        ],

        '__content_releaser__' => 
        [ 
         '__default__', 
         'content_releaser',
        ],

        '__content_admin__' =>
        [
         '__default__',
         'content_admin',
        ],
      }

      @content_types =
        [
         [ 'phrase',   'phrase',   'Localized short phrases', nil, 'text/*' ],
         [ 'email',    'email',    'Localized email templates', nil, 'text/*', 'Contenter::Plugin::Email' ],
         [ 'faq',      'faq',      'Localized frequently asked questions', nil, 'text/*' ],
         [ 'contract', 'contract', 'Localized contract template', /\A[-a-z0-9_]+(\/[-a-z0-9_]+)*\Z/i, 'text/*' ],
         [ 'image',    'image',    'Graphic image', nil, 'image/*', 'Contenter::Plugin::Image' ],
         [ 'sound',    'sound',    'Sound', nil, 'audio/*' ],
        ]

      @content_statuses = 
        [
         [ 'initial',  'Initial state' ],
         [ 'created',  'Newly created' ],
         [ 'modified', 'Recently modified' ],
         [ 'deleted',  'Recently deleted' ],
         [ 'approved', 'Approved for testing' ],
         [ 'released', 'Released for production' ],
        ]

      @countries =
        [
         [ '_',  'Any Country', 'Wildcard' ],
         [ 'US', 'United States of America' ],
         [ 'GB', 'Great Britain' ],
         [ 'AU', 'Australia' ],
         [ 'CA', 'Canada' ],
        ]

      @languages =
        [
         [ '_', 'Any Language', 'Any Language' ],
         [ 'en', 'English' ],
         [ 'es', 'Spanish' ],
         [ 'fr', 'French' ],
        ]

      @brands =
        [
         [ '_',   'Any Brand',     'Wildcard Brand' ],
         [ 'test', 'Test Brand',  'For testing' ],
        ]

      @applications =
        [
         [ '_',      'Any Application', 'Wildcard' ],
         [ 'test',   'Test Application', 'For testing' ],
        ]

      @mime_types =
        [
         # code            name,    description,          mime_type_super
         [ '*/*',          nil,     'Any mime type',      nil ],
         [ '_',            'Any',   'Wildcard Mime Type', '*/*' ],
         [ 'text/*',       'Text',  'Any text format',    '*/*' ],
         [ 'text/plain',   nil,     'Plain Text',         'text/*' ],
         [ 'text/html',    nil,     'HTML Text',          'text/*' ],
         [ 'text/css',     nil,     'Cascading Style Sheet',  'text/*' ],
         [ 'text/csv',     nil,     'Comma Separated Values', 'text/*' ],
         [ 'image/*',      'Image', 'Any image format',   '*/*',   ],
         [ 'image/jpeg',   nil,     "JPEG image format",  'image/*' ],
         [ 'image/png',    nil,     "PNG image format",   'image/*' ],
         [ 'image/gif',    nil,     "GIF image format",   'image/*' ],
         [ 'audio/*',      'Audio', "Any audio format",   '*/*' ],
         [ 'audio/x-wav',  'wav',   'WAV audio format',   'audio/*' ],
         [ 'audio/mpeg',   'mpeg',  'MPEG audio format',  'audio/*' ],
         [ 'audio/flac',   'flac',  'FLAC audio format',  'audio/*' ],
        ]

      @version_list_names =
        [
         :production,
         :development,
         :integration,
        ]
     
      self
    end


    def initialize opts = { }
      @all_actions ||= self.class.all_actions.dup

      data_default!

      opts.each do | k, v |
        s = "#{k}="
        send(s, v) if respond_to? s
      end

      instance_eval { yield } if block_given?
    end


    # invokes every other creation method explicitly (implicity is the devil!)
    def all!
      return self if already_seeded?
      $stderr.puts "  all!:"
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
        UserTracking.with_default_user(1) do
          send(action)
        end
      end
      self
    end


    # Returns true if database is already seeded.
    def already_seeded?
      false # ! ! User[users.first] 
    end


    ##################################################################
    # Seed data creation methods
    #
    # Each method is expected to test for pre-existing data by code or name.
    #

    def core_users!
      users.each do | x |
        # Default "user" to login="user", "password" = "useruser"
        x = [ x.to_s, x.to_s + x.to_s ] unless Array === x
        login, password = *x

        login = login.to_s
        password = password.to_s[0 .. 39]

        if user = User.find(:first, :conditions => { :login => login })
          # $stderr.puts "      User #{login.inspect} already exists, skipping."
        else
          seed = 
            {
            :login => login,
            :name => login,
            :email => "#{login.gsub('_', '-')}@localhost.com".downcase,
            :password => password,
          }
          $stderr.puts "    + User #{login.inspect}"
          seed[:password_confirmation] = password
          # PP.pp(seed, $stderr)
          user = User.create!(seed)
        
          # $stderr.puts "     password: #{password.inspect}"
        end
      end
    end
    
    def core_roles!
      Role.build_role_capability *@role_capability
    end

    def core_user_roles!
      user_roles.each do | user, roles |
        Role.build_user_role user, *roles
      end
    end

    # Creates statuses!
    def core_content_status!
      UserTracking.current_user = 'root'
      content_statuses.each do | r |
        unless ContentStatus[r[0]]
          ContentStatus.create!({
                                  :code => r[0],
                                  :name => r[0],
                                  :description => r[1] || '',
                                })
        end
      end
    end

    # Creates standard content types.
    def core_content_types!
      content_types.each do | r |
        raise ArgumentError, "no content_type name #{r.inspect}" unless r[0]
        if o = ContentType[r[0]]
          if o.mime_type == MimeType[:_]
            o.mime_type = MimeType[r[4]] || (raise "no MimeType[#{r[4].inspect}]")
            o.save!
          end

          r[5] ||= ''
          if o.plugin != r[5]
            o.plugin = r[5]
            o.save!
          end

          d = r[6] || { }
          unless d.empty?
            o.aux_data.update(d)
            o.save!
          end

        else
          ContentType.create!(:code => r[0], 
                              :name => r[1] || r[0],
                              :description => r[2]  || '',
                              :key_regexp => (r[3] || /\A.+\Z/).inspect,
                              :mime_type => MimeType[r[4]] || (raise "No MimeType[#{r[4].inspect}]"),
                              :plugin => r[5],
                              :aux_data => r[6] || { }
                              )
        end
      end
    end

    def core_mime_types!
      mime_types.each do | r |
        r[3] &&= MimeType[r[3]] || raise("Cannot find MimeType[#{r[3].inspect}]")
        if o = MimeType[r[0]]
          if o.mime_type_super != r[3]
            o.mime_type_super = r[3]
            o.save!
          end
          d = r[4] || { }
          unless d.empty?
            o.aux_data.update(d)
            o.save!
          end
        else
          $stderr.puts "    + #{r[0].inspect}"
          MimeType.create!(:code => r[0], 
                           :name => r[1] || r[0],
                           :description => r[2] || '',
                           :mime_type_super => r[3],
                           :aux_data => r[4] || { }
                           )
        end
      end
    end

    def create_or_update_axis_objects! cls, data
      data.each do | r |
        if o = cls[r[0]]
          d = r[3] || { }
          unless d.empty?
            o.aux_data.update(d)
            o.save!
          end
        else
          o = cls.
            create!(:code => r[0], 
                    :name => r[1], 
                    :description => r[2] || '',
                    :aux_data => r[3] || { })
        end
      end
    end

    def core_languages!
      create_or_update_axis_objects! Language, languages
    end

    def core_countries!
      create_or_update_axis_objects! Country, countries
    end

    def core_brands!
      create_or_update_axis_objects! Brand, brands
    end

    def core_applications!
      create_or_update_axis_objects! Application, applications
    end

    def core_vls!
      unless VersionList.count > 0
        VersionList.create(:comment => 'Default version list')
      end
    end


    # Creates standard version list names - deprecated
    def core_vlns!
      UserTracking.current_user = 'root'

      # Create some VLNs.
      version_list_names.each do | n |
        unless VersionListName.find(:first, :conditions => { :name => n.to_s })
          $stderr.puts "  VersionListName: #{n.to_s.inspect}"
          VersionListName.create!(:name => n.to_s, 
                                  :description => '', 
                                  :version_list => VersionList.first
                                  )
        end
      end
    end

    def inspect
      to_s
    end
  end # class
end # module
