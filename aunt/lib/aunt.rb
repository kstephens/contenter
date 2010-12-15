
# Base module for the Aunt Authororization framework.
# http://contenter.org.
module Aunt
  EMPTY_STRING = ''.freeze
  EMPTY_HASH = { }.freeze
  EMPTY_ARRAY = [ ].freeze
  UNDERSCORE = '_'.freeze  # Used as "ANY" wildcard in AUNT.
  SPACE = ' '.freeze
  
  def self.rails_config config
    fixme
  end
end # module


require 'aunt/error'


