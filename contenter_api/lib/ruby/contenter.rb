
# Base module for the Contenter Enterprise CMS.
# http://contenter.org.
module Contenter
  EMPTY_STRING = ''.freeze unless defined? EMPTY_STRING
  EMPTY_HASH = { }.freeze  unless defined? EMPTY_HASH
  EMPTY_ARRAY = [ ].freeze unless defined? EMPTY_ARRAY
  UNDERSCORE = '_'.freeze  unless defined? UNDERSCORE # Used as "ANY" wildcard in contenter.
end # module


require 'contenter/error'


