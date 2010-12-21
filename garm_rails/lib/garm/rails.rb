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
      [ lib_dir, 
        "#{lib_dir}/../app/models",
        "#{lib_dir}/../app/controllers",
        "#{lib_dir}/../app/helpers",
        ].each do | dir |
        dir = File.expand_path(dir)
        config.load_paths += [ dir ] if File.directory? dir
        config.controller_paths += [ dir ] if dir =~ %r{/controllers$/}
      end
      config.after_initialize do
        dir = File.expand_path("#{lib_dir}/../app/views")
        if File.directory? dir
          ActionController::Base.view_paths << dir # Rails 2.2.2
          # config.view_paths += [ dir ]
        end
      end
    end
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
    
    # Assume these default routes:
    # map.connect ':controller/:action/:id'
    # map.connect ':controller/:action/:id.:format'
    # map.connect ':controller/:action'
    # map.connect ':controller/:action.:format'
  end

  end # module
end # module



