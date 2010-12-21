# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.2.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# Use engines for 2.2.2.
# require File.join(File.dirname(__FILE__), '../vendor/plugins/engines/boot') 

# F*CKING rails pluralization, back-and-forth crap.
# Shouldn't this be in boot.rb?
require 'active_support/inflector'
ActiveSupport::Inflector.inflections do | inflect |
  # Handle ContentStatus
  inflect.singular /^(.*)(status)$/i, '\1\2'
  inflect.plural   /^(.*)(status)$/i, '\1\2es'
  inflect.singular /^(.*)(status)es$/i, '\1\2'
end

# Use garm: core, api, rails.
require File.expand_path("#{RAILS_ROOT}/../garm_core/init.rb")
require File.expand_path("#{RAILS_ROOT}/../garm_api/init.rb")
require File.expand_path("#{RAILS_ROOT}/../garm_rails/init.rb")

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]
  config.frameworks -= [ :active_resource ]

  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  # MAC OSX: config.gem 'postgres' failed for me unless I had already done 
  #          PG_CONFIG=/Library/PostgreSQL/8.3/bin/pg_config sudo gem install pg
  #          even though I added this to my PATH as the error instructed
  # My current config is 
  # pg (0.8.0)
  # postgres (0.7.9.2008.01.28)
  config.gem "postgres" 
  # config.gem "archive-zip"
  config.gem "fastercsv"

  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "aws-s3", :lib => "aws/s3"

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )
  config.load_paths += %W( #{RAILS_ROOT}/app/streamlined )
  config.load_paths += [ File.expand_path("#{RAILS_ROOT}/../contenter_api/lib/ruby") ]
  config.load_paths += [ File.expand_path("#{RAILS_ROOT}/../../contenter_api/lib/ruby") ]
  config.load_paths += [ File.expand_path("#{RAILS_ROOT}/../cabar_core/lib/ruby") ]
  config.load_paths += [ File.expand_path("#{RAILS_ROOT}/../../cabar/comp/cabar_core/lib/ruby") ]

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Comment line to use default local time.

  # fixes: http://www.railsformers.com/article/activerecord-timezone-settings-bug
  config.time_zone = 'UTC'
  config.active_record.default_timezone = :utc

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_contenter_session',
    :secret      => '79dad13facabdc939924b59365ccc9642768fb3ecb9a47e33377d2c76e8bc4c200eacb7fd7f23a60d3c3e93414e3d66e0ef38c7f065b8fd3d784fb2214002767'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  config.action_controller.session_store = :active_record_store

  # dump to sql not schema.rb format (though I doubt this preserves DDL
  # generated through execute calls. Note: contrary to rails documentation, this
  # is NOT dumped via db:schema:dump, rather by db:structure:dump !
  config.active_record.schema_format = :sql


  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # debugger

  # Garm plugin activation.
  Garm::Rails.config! config

=begin
  $stderr.puts "config.load_paths = #{config.load_paths.inspect}"
  $stderr.puts "config.controller_paths = #{config.controller_paths.inspect}"
  # $stderr.puts "config.view_paths = #{ActionController::Base.view_paths.inspect}"
=end
end


