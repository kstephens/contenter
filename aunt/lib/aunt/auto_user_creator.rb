require 'aunt'

require 'yaml'
require 'erb'

module Aunt
  # Class responsible for creating new Users and defining their Roles after
  # Basic HTTP auth.
  class AutoUserCreator
    attr_accessor :config_file, :config

    def config_file
      @config_file ||= "#{RAILS_ROOT}/config/auto_users.yml"
    end

    def config
      @config ||= 
        YAML.load(ERB.new(File.read(config_file)).result(binding))
    end

    def all!
      config['user'].keys.compact.each do | user_name |
        user! user_name
      end
    end

    # Creates a new User if it does not exist.
    # Added the roles to the User as specified
    # in #config.
    def user! opts
      opts = { :login => opts } if String === opts

      user = opts.delete(:user)

      User.transaction do
        unless user = User[opts[:login]]
          opts[:name] ||= opts[:login]
          opts[:email] ||= config['email']['template'] % opts[:login]
          # .gsub(/#\{([^\}]+)\}/){ | k | opts[k.to_sym] }
          opts[:password] ||= opts[:login] + opts[:login]
          opts[:password_confirmation] ||= opts[:password]
          
          $stderr.puts "#{self.class.name}: creating User[#{opts[:login].inspect}]"
          user = User.create!(opts)
        end

        roles_for_user(user.login).each do | role_name |
          role = Role[role_name] || (raise "No Role named #{role_name.inspect}")
          unless user.roles.include?(role)
            add_user_role!(user, role)
          end
        end
      end

      user
    end
    alias :create_user! :user!

    # Returns the roles for a user.
    def roles_for_user login
      cu = config['user']
      role_alias = cu[login] || cu[nil]
      role_alias = [ role_alias ] unless Array === role_alias
      roles = [ ]
      role_alias.each do | ra |
        roles.concat config['roles'][ra] || [ ra ]
      end
      roles.uniq!
      roles
    end

    def add_user_role! user, role
      $stderr.puts "  + User[#{user.to_s.inspect}].roles << Role[#{role.to_s.inspect}]"
      user.roles << role
    end
  end
end
