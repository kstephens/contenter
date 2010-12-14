# See cabar_comp_require 'cabar_core'

module Cabar
  EMPTY_HASH = { }.freeze  unless defined? EMPTY_HASH
  EMPTY_ARRAY = [ ].freeze unless defined? EMPTY_ARRAY
  EMPTY_STRING = ''.freeze unless defined? EMPTY_STRING

  SEMICOLON = ';'.freeze
  COLON = ':'.freeze

  # Returns first dotted part of CABAR_HOSTNAME or system hostname.
  def self.hostname
    @@hostname ||= 
      (
       ENV['CABAR_HOSTNAME'] || 
       Socket.gethostname
       ).sub(/\..*/, '').freeze
  end


  # Returns the path separator for this platform.
  # UNIX: ':'
  # Windows: ';'
  def self.path_sep
    @@path_sep ||= (ENV['PATH'] =~ /;/ ? SEMICOLON : COLON)
  end


  # Split all the elements in a path.
  # Remove any empty elements.
  def self.path_split path, sep = nil
    sep ||= path_sep
    path = path.split(sep)
    path.reject{|x| x.nil? || x.empty?}
    path
  end
  

  # Joins directory elements into a path.
  # Removes any nil or empty elements.
  def self.path_join *args
    sep = path_sep
    path = args.flatten.reject{|x| x.nil? || x.empty?}
    path = path.uniq.join(sep)
    path = path_split(path, sep)
    path = path.uniq.join(sep)
    path
  end


  # Expand all the elements in a path,
  # while leaving '@' prefixes.
  def self.path_expand p, dir = nil
    case p
    when Array
      p.map { | p | path_expand(p, dir) }.cabar_uniq_return!
    else
      p = p.to_s.dup
      if p.sub!(/^@/, EMPTY_STRING)
        '@' + File.expand_path(p, dir)
      else
        File.expand_path(p, dir)
      end
    end
  end

  # Construct a cabar YAML header.
  def self.yaml_header str = nil
"---
cabar:
  version: #{Cabar.version.to_s.inspect}
" + (str ? "  #{str}:" : EMPTY_STRING)
  end

end # module


# Placeholder for rails autoloader
module CabarCore
end


require 'cabar/array'
require 'cabar/hash'
require 'cabar/file'

require 'cabar/base'
require 'cabar/error'

