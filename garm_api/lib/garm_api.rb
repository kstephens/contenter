
begin
  dir = File.expand_path("../../../garm_core/lib", __FILE__)
  # $stderr.puts "dir = #{dir.inspect}"
  if File.directory?(dir)
    $:.unshift(dir) unless $:.include?(dir)
  end
end

require 'garm'
require 'garm/api'
require 'garm/authorization_cache'
require 'garm/authorization_cache/methods'

