require 'garm/wildcard'

# Rename to Garm::CapabilityExpand?
module CapabilityHelper
  include Garm::Wildcard

  def capability_expand cap
    return cap if Array === cap
    (@@capability_expand ||= { })[cap] ||=
      begin
        # $stderr.puts "  capability_expand #{cap.inspect} => "
        if cap !~ /<<.+>>/ && cap =~ /\Acontroller\/(.*)/
          cap = 'controller/' + $1.scan(/(?:<<)?([^\/]+)(?:>>)?/).map{|m| "<<#{m[0]}>>"}.join('/')
        end
        result = enumerate_wildcard(cap).freeze
        # $stderr.puts "  #{result.inspect}"
        result
      end
  end

  extend self
end


