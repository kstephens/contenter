
require 'contenter'

module Contenter
class Api
  # A Hash with a Time-to-live per element.
  # Expired values are removed by calling check_time_to_live!.
  class HashTtl < ::Hash
    attr_accessor :now, :ttl, :ttl_bias

    def initialize *args
      @now = nil
      @ttl = 0
      @ttl_bias = false
      super
    end

    def now
      @now ||= 
        Time.now
    end

    alias :get_with_ttl :[]

    # Returns the value stored for the key.
    # Use #get_with_ttl to return the key [ value, ttl ].
    def [](k)
      v = super(k)
      v && v.first
    end

    # Sets the value stored for key.
    # Sets the TTL of the value to self.now + ttl + a random bias.
    def []=(k, v)
      super(k, [ v, now.to_i + ttl + (ttl_bias && ttl_bias > 1 ? rand(ttl_bias) : 0)])
    end


    # Returns values without ttl values.
    # Use values_with_ttl to return [ [ value, ttl ], ... ].
    def values_without_ttl
      values_with_ttl.map{|x| x.first}
    end
    alias :values_with_ttl :values
    alias :values :values_without_ttl


    # Yields key and value with block.
    # Use each_with_ttl to yield to key, [ value, ttl ].
    def each_without_ttl
      each_with_ttl.each{ |k, v| yield k, v.first }
    end
    alias :each_with_ttl :each
    alias :each :each_without_ttl


    # Removes all key/value pairs that expired as of now.
    # Returns an array of all expired keys.
    # Updates self.now to now.
    def check_time_to_live! now = nil
      now ||= Time.now
      now_i = now.to_i

      expired = select do | k, v |
        # $stderr.puts "  k = #{k.inspect} v = #{v.inspect} now_i = #{now_i.inspect}"
        v[1] < now_i
      end

      expired = expired.map do | k, v |
        # $stderr.puts "  k = #{k.inspect} v = #{v.inspect}"
        delete(k)
        k
      end

      self.now = now

      # $stderr.puts "expired = #{expired.inspect}"

      expired
    end
  end # class
end # class
end # module

