
# Base module for the Garm Authorization framework.
# http://contenter.org.
module Garm
  EMPTY_STRING = ''.freeze
  EMPTY_HASH = { }.freeze
  EMPTY_ARRAY = [ ].freeze
  UNDERSCORE = '_'.freeze  # Used as "ANY" wildcard in Garm.
  SPACE = ' '.freeze
end # module


require 'garm/error'


