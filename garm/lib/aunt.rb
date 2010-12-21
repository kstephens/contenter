
# Base module for the Garm Authorization framework.
# http://contenter.org.
module Garm
  EMPTY_STRING = ''.freeze
  EMPTY_HASH = { }.freeze
  EMPTY_ARRAY = [ ].freeze
  UNDERSCORE = '_'.freeze  # Used as "ANY" wildcard in Garm.
  SPACE = ' '.freeze
  
  # Refactor to Garm::Rails?
  # Call from Rails application Initializer block.
  def self.rails_config! config
    dir = File.expand_path("#{__FILE__}/..")
    config.load_paths += [ dir ]

    dir = File.expand_path("#{__FILE__}/../../app/models")
    config.load_paths += [ dir ]
    
    dir = File.expand_path("#{__FILE__}/../../app/controllers")
    config.load_paths += [ dir ] 
    config.controller_paths += [ dir ]
    
    dir = File.expand_path("#{__FILE__}/../../app/helpers")
    config.load_paths += [ dir ]

    config.after_initialize do
      dir = File.expand_path("#{__FILE__}/../../app/views")
      ActionController::Base.view_paths << dir # Rails 2.2.2
      # config.view_paths += [ dir ]
    end
  end

  # Call from Rails application routes.rb block.
  def self.rails_routes! map
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


require 'garm/error'


