module Contenter
  # A generic failover delegate.
  # 
  # Example:
  #
  #
  # log_error = lambda { | delegate_hash, sel, args, error |
  #   $stderr.puts "#{delegate_hash[:name]}: #{sel} #{error.inspect}"
  # }
  # fd = Contenter::FailoverDelegate.new(:on_error => log_error, :delegates =>
  #   [
  #     { :name => :obj1, :delegate => obj1, :priority => 1, :blacklist_interval => 60 },
  #     { :name => :obj2, :delegate => obj2, :priority => 2, :blacklist_interval => 90 },
  #     { :name => :obj3, :delegate => obj3, :priority => 3 },
  #   ])
  #
  # If obj1 fails, log_error, blacklist it for 60 seconds,
  # if obj2 fails, log_error, blacklist it for 90 seconds,
  # if obj3 fails, log_error, reraise error.
  #
  # Overview
  #
  # * Initialize #available_delegates with prioritized copy of #delegates.
  # * If no delegates are available, throw Error:NoDelegate exception.
  # * Delegate #method_missing request to the first delegate in #available_delegates.
  # ** If exception is thrown during request to first delegate,
  # *** log the failure,
  # *** note the time of the failure,
  # *** annotate how long the delegate should be blacklisted.
  # *** remove delegate Hash from #available_delegates,
  # *** append to delegate Hash to #blacklisted_delegates. 
  # * A delegate with a blacklist_interval < 0 will cause error to be rethrown.
  # * Periodically, check blacklisted delegates for reinclusion into available delegates. 
  #
  class FailoverDelegate
    class Error < ::Exception
      class NoDelegate < self; end
    end

    module Behavior
    # Arrays of Hashes defining delegates.
    # 
    # Each element is a Hash:
    #
    # * :delegate = the object to delegate the method_missing intercept to.
    # * :blacklist_interval - the number of seconds to blacklist this delegate in the event of an error, defaults to 0
    # * :priority - the relative priority of the delegate, defaults to order in Array.
    #
    attr_accessor :delegates
    
    # Array of Hashes defining available delegates orderd by :priority.
    attr_accessor :available_delegates
    
    # Array of Hashes of blacklisted delegates.
    attr_accessor :blacklisted_delegates
    
    # Default handler Proc for any error.
    # Each delegate Hash can also specify an :on_error.
    attr_accessor :on_error


    def initialize opts
      @on_error = opts[:on_error]

      @delegates = opts[:delegates]

      # Assign priorities.
      priority = 1
      @delegates.each do | h |
        priority = h[:priority] ||= (priority += 1)
        h[:blacklist_interval] ||= 0
      end

      @available_delegates = @delegates.dup
      @blacklisted_delegates = [ ]

      prioritize_available_delegates!
    end

    
    def prioritize_available_delegates!
      @available_delegates.sort!{ | a, b | a[:priority] <=> b[:priority] }
      self
    end


    def on_error! delegate_desc, exception
      error_proc = delegate_desc[:on_error] || @on_error
      error_proc && error_proc.call(delegate_desc, exception, @error_method, @error_args)
    end


    def available_delegate
      @available_delegates.first || 
        raise(Error::NoDelegate)
    end


    def blacklist_delegate! d
      @available_delegates.delete(d)
      @blacklisted_delegates << d unless @blacklisted_delegates.include?(d)
      self
    end


    # Should be called periodically.
    def check_blacklisted_delegate_intervals! now = nil
      now ||= _now
      @blacklisted_delegates.dup.each do | d |
        if d[:blacklist_until] < now
          d[:blacklist_until] = nil
          @blacklisted_delegates.delete(d)
          @available_delegates << d unless @available_delegates.include?(d)
        end
      end
      prioritize_available_delegates!
    end


    def _now
      @_now ||
      Time.now
    end


    def with_delegate! 
      # Get next available delegate,
      # allow Error::NoDelegate to bubble up.
      d = available_delegate
      begin
        yield d
      rescue Exception => err
        now = _now
        d[:last_error] = {
          :time => now,
          :method => @error_method,
          :args => @error_args,
          :error => err,
        }
        # Rethrow exception because
        # this delegate has no blacklist_interval and there are no other available_delegates
        if d[:blacklist_interval] <= 0 
          # err.instance_var_set!("@original_backtrace", err.backtrace.dup)

          on_error!(d, err)

          raise err
        else
          d[:blacklist_until] = now + d[:blacklist_interval]
          blacklist_delegate!(d)

          on_error!(d, err)

          # Select next available delegate
          d = available_delegate

          # Try again.
          retry
        end
      end
    end
    end # module

    include Behavior

    # Delegate method to available delegate.
    def method_missing sel, *args, &blk
      @error_method = sel
      @error_args = args
      with_delegate! do | d |
        d[:delegate].send(sel, *args, &blk)
      end
    end 

  end # module
end # module
