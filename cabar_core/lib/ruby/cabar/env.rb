require 'cabar_core'

module Cabar
  # ENV Environment variable support.
  module Env

    # Executes block while defining the dst Hash with each element of env.
    # dst is restored after completion of the block.
    # nil values are equivalent to deleting the dst key/value.
    #
    # dst defaults to the global ENV
    # NOT THREAD-SAFE.
    def with_env env, dst = nil
      dst ||= ENV
      dst_save = { }

      env.each do | k, v |
        k = k.to_s
        dst_save[k] = dst[k]
        if v
          dst[k] = (v = v.to_s)
        else
          dst.delete(k)
        end
        # $stderr.puts "  #{k}=#{v.inspect}"
      end

      yield

    ensure
      env.keys.each do | k |
        k = k.to_s
        if v = dst_save[k]
          dst[k] = v
        else
          dst.delete(k)
        end
        # $stderr.puts " RESTORE #{k}=#{v.inspect}"
      end
    end
    
  end # module

end # module

