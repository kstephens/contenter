
# Base module for the Aunt Authororization framework.
# http://contenter.org.
module Aunt
  EMPTY_STRING = ''.freeze
  EMPTY_HASH = { }.freeze
  EMPTY_ARRAY = [ ].freeze
  UNDERSCORE = '_'.freeze  # Used as "ANY" wildcard in AUNT.
  SPACE = ' '.freeze
  
  # Call from Rails application Initializer block.
  def self.rails_config! config
    config.load_paths += [ File.expand_path("#{__FILE__}/..") ]
    config.load_paths += [ File.expand_path("#{__FILE__}/../../app/models") ]
    config.load_paths += [ File.expand_path("#{__FILE__}/../../app/controllers") ]
  end
end # module


require 'aunt/error'


