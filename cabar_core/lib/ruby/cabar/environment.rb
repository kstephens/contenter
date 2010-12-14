
require 'cabar_core'

require 'cabar/env'

module Cabar
  # Environment variable manager.
  # Standin for global ENV.
  # Handles read-only, inherited and locked values.
  class Environment
    include Cabar::Env

    VALUE   = 'value'.freeze
    INHERIT = 'inherit'.freeze
    DEFAULT = 'default'.freeze
    LOCKED  = 'locked'.freeze

    def initialize opts = nil
      @h = { }
      @data = { }
      from_opts! opts if opts
    end

    def from_opts! opts
      opts.each do | key, value |
        case value
        when Hash
          value = value.dup
          has_v = value.key?(VALUE)
          v = value.delete(VALUE)
          set_v = true
          case
          when value[INHERIT]
            v = value[DEFAULT] = ENV[key]
          when value[LOCKED]
            set_v = false unless has_v
          end
          @h[key] = v if set_v
          @data[key] = value
        else
          @h[key] = value && value.dup
        end
      end
      self
    end

    def dup
      super.dup_deepen!(self)
    end


    def dup_deepen! src
      @h = @h.dup
      @data = @data.dup
      @data.each { | k, v | @data[k] = v.dup }
      self
    end


    def [](key)
      raise TypeError, "key must be String" unless String === key
      @h[key]
    end


    def []=(key, value)
      @h[check_read_only!(key)] = value unless inherit?(key) || locked?(key)
    end


    def check_read_only! key
      raise TypeError, "key must be String" unless String === key
      raise ArgumentError, "key #{key.inspect} is read-only" if read_only?(key)
      key
    end


    # Marks a key read-only.
    # Returns self.
    def read_only! key
      set_data! key, :read_only, true
      self
    end

    
    # Returns true if the value for key is marked 'read_only'.
    # If so, any attempt to call []= will result in an ArgumentError.
    def read_only? key
      ! ! data(key, :read_only)
    end


    # Returns true if the value for key is marked 'inherited'.
    # If so, any attempt to call []= will be ignored and
    # the value returned from [] will the ENV[key] value at initialization.
    def inherit? key
      ! ! (data(key, INHERIT) && data(key, DEFAULT))
    end


    # Returns true if the value for key is marked 'locked'
    # If so, any attempt to call []= will be ignored.
    def locked? key
      ! ! data(key, LOCKED)
    end


    def each &blk
      @h.each &blk
    end


    def keys
      @h.keys
    end


    def values
      @h.values
    end


    def delete *args
      args.each do | k |
        @h.delete(check_read_only!(k))
      end
    end


    def to_hash
      @h.dup
    end


    def from_hash! h
      h.each do | k, v |
        self[k] = v unless inherit?(k)
      end
      self
    end


    # Executes block while setting dst with each element of env.
    # dst is restored after completion of the block.
    # nil values are equivalent to deleting the dst element
    #
    # dst defaults to the global ENV
    #
    # NOT THREAD-SAFE if dst == ENV
    def with dst = nil
      dst ||= ENV
      with_env(@h, dst) do
        yield
      end
    end

    private

    def data key, k 
      (@data[key] || EMPTY_HASH)[k]
    end


    def set_data! key, k, value
      (@data[key] ||= { })[k] = value
    end


  end # module

end # module

