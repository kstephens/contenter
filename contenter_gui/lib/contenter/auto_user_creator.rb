require 'contenter'

module Contenter
  class AutoUserCreator
    def config_file
      @config_file ||= "#{RAILS_ROOT}/config/auto_users.yml"
    end

    def config
      @config ||= YAML.load_file(config_file)
    end

    def create_user! opts
      opts = { :login => opts } if String === opts

      user = User[opts[:login]]
      raise ArgumentError, "User #{opts[:login].inspect} exists" if user

      opts[:name] ||= opts[:login]
      opts[:email] ||= config['email']['template'] % opts[:login]
        # .gsub(/#\{([^\}]+)\}/){ | k | opts[k.to_sym] }
      opts[:password] ||= opts[:login] + opts[:login]
      opts[:password_confirmation] ||= opts[:password]

      User.transaction do
        user = User.create!(opts)
        
        roles_for_user(user.login).each do | role_name |
          user.roles << (Role[role_name] || (raise "No Role named #{role_name.inspect}"))
        end
      end

      user
    end

    def roles_for_user login
      cu = config['user']
      role_alias = cu[login] || cu[nil]
      roles = config['roles'][role_alias]
    end

  end
end
