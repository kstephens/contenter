# Used to set up common test environments and tools for
# contenter tests.

RAILS_ENV = (ENV['RAILS_ENV'] || 'test').dup.freeze unless defined? RAILS_ENV

