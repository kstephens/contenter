module Aunt
    
  # Defines the tasks necessary to seed the aunt database to a usable state.
  class Seeder

    # Seed data arrays.
    attr_accessor :role_capability, :users, :user_roles

    # List of actions to perform.
    attr_accessor :all_actions

    def self.all_actions
      @@all_actions ||=
        [
         :core_users!,
         :core_roles!,
         :core_user_roles!,
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
             'controller/+/{index,list,show,search}' => true,
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

        ]

      @users = 
        [ 
         'root',
         '__test__',
         '__default__',
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
      }
     
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

    def inspect
      to_s
    end
  end # class
end # module
