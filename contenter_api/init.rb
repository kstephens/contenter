begin
  dir = File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'ruby'))
  $:.unshift(dir) unless $:.include?(dir)
end

require 'contenter/bulk'
require 'contenter/error'

