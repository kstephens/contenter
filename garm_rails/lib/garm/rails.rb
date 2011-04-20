require 'garm_core'
require 'garm_api'

module Garm
  # Base module for the Garm Authorization framework Rails component.
  # http://contenter.org.
  module Rails
    def self.lib_dir
      @@lib_dir ||= File.expand_path("../..", __FILE__).freeze
    end

  # Call from Rails application Initializer block.
  def self.config! config
    [ Garm::Core, Garm::Api, Garm::Rails ].each do | m |
      lib_dir = m.lib_dir
      config_lib_dir! config, lib_dir
    end
    self
  end

  # Adds basic Rails::Initializer configuration for a Rails-style plugin based on a typical -I lib_dir.
  def self.config_lib_dir! config, lib_dir
    lib_dir = File.expand_path(lib_dir)
    # $stderr.puts "  ### #{self}.config_dir! #{lib_dir.inspect}"
      [ lib_dir, 
        "#{lib_dir}/../app/models",
        "#{lib_dir}/../app/controllers",
        "#{lib_dir}/../app/helpers",
        ].each do | dir |
        if File.directory?(dir = File.expand_path(dir))
          # $stderr.puts "   + #{dir.inspect}"
          config.load_paths += [ dir ] unless config.load_paths.include?(dir)
          config.controller_paths += [ dir ] if dir =~ %r{/controllers\Z} && ! config.controller_paths.include?(dir) 
        end
      end
      if File.directory?(dir = File.expand_path("#{lib_dir}/../vendor/plugins"))
        # $stderr.puts "   + #{dir.inspect}"
        config.plugin_paths += [ dir ] unless config.plugin_paths.include?(dir)
      end
      if File.directory?(dir = File.expand_path("#{lib_dir}/../app/views"))
        config.after_initialize do
          # $stderr.puts "   + #{dir.inspect}"        
          ActionController::Base.view_paths << dir unless ActionController::Base.view_paths.include?(dir) # Rails 2.2.2
          # config.view_paths += [ dir ] unless config.view_paths.include?(dir) # Rails 3.x?
        end
      end
    self
  end

  # Call from Rails application routes.rb block.
  def self.routes! map
    map.logout '/logout', :controller => 'sessions', :action => 'destroy'
    map.login '/login', :controller => 'sessions', :action => 'new'
    map.register '/register', :controller => 'users', :action => 'create'
    map.signup '/signup', :controller => 'users', :action => 'new'
    
    # Hacks for streamlined .vs. restful auth.
    map.connect 'users/list', :controller => 'users', :action => 'list'
    map.connect 'users/show/:id', :controller => 'users', :action => 'show'
    map.connect 'session/destroy', :controller => 'sessions', :action => 'destroy'
    map.connect 'sessions/become_user', :controller => 'sessions', :action => 'become_user'
    map.connect 'sessions/become_real_user', :controller => 'sessions', :action => 'become_real_user'
    
    map.resource :session
    
    # Assume these default routes are in the main application config/routes.rb:
    # map.connect ':controller/:action/:id'
    # map.connect ':controller/:action/:id.:format'
    # map.connect ':controller/:action'
    # map.connect ':controller/:action.:format'
  end

  end # module
end # module

