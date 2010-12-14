require 'contenter'

require 'contenter/error'

module Contenter
  # Application Interface to Contenter content.
  #
  # Language:
  #
  #   Contenter::Api.get(:phrase, :hello).to_s
  #   => "hello"
  #
  #   Contenter::Api.get(:phrase, :hello, :language => :es).to_s
  #   => "hola"
  #
  # Branding:
  #
  #   Contenter::Api.get(:phrase, :company_name).to_s
  #   => "ThisCompany"
  #
  #   Contenter::Api.get(:phrase, :company_name, :brand => :OTHER).to_s
  #   => "OtherCompany"
  #
  # Dynamic Scoping:
  #
  #   Contenter::Api::Selector.with(:brand => :OTHER) do
  #     Contenter::Api.get(:phrase, :company_name).to_s
  #   end
  #   => "OtherCompany"
  #
  #   Contenter::Api.get(:phrase, :company_name, :brand => :OTHER).to_s
  #   => "OtherCompany"
  #
  # See Contenter::Api::Selector for more details.
  #
  # See Contenter::Api::Type::* for additional content types.
  class Api
    Error = ::Contenter::Error

    # Default for cache TTL and cache TTL random bias.
    attr_accessor :cache_ttl, :cache_ttl_bias

    # The current cache of HashTTL objects for each registered Api::Type.
    attr_reader :cache

    # The current Logger object.
    attr_accessor :logger

    # The configuration Hash or Proc that returns a Hash.
    attr_accessor :config


    # Configure the Contenter::Api system.
    # Should be called only once.
    def self.configure!
      Selector.configure!
    end


    # Returns the process default instance.
    # Additional parameters are used only once to initialize the instance.
    def self.instance opts = EMPTY_HASH
      @instance ||= 
        self.new(opts)
    end


    # Sets the default instance.
    def self.instance= x
      @instance = x
    end


    # Returns the thread-default instance.
    # Returns the process-default instance if thread instance is not defined.
    def self.current 
      Thread.current[:'Contenter::Api.current'] ||=
        @instance
    end

    # Sets the Thread-current instance.
    def self.current= x
      Thread.current[:'Contenter::Api.current'] = x
    end

    
    def initialize opts = EMPTY_HASH
      @config = nil
      @logger = nil
      @selector = nil
      @cache_ttl = nil
      @cache_ttl_bias = false
      @cache = { }
      @fallback_cache = { }
      @type = { }
      @store = { }
      opts.each do | k, v |
        send("#{k}=", v)
      end
    end


    # Get the currently active content Selector.
    def selector
      @selector || 
        Selector.current
    end

    
    # Main API:
    #
    # Returns content for a content type based on its key.
    #
    # sel defaults to Selector.current 
    def get type, key, sel = nil
      # Error thrown from backend.
      error = nil

      # Convert options to selector.
      sel = fix_selector sel

      # Keep current selector for recursion by StringTemplate#t.
      selector_save = @selector
      @selector = sel

      # Convert type to a Api::Type.
      type = coerce_type(type)

      # Coerce key to a Symbol.
      key = type.coerce_key(key)

      # Check cache.
      sel_cache = (@cache[type] ||= { })
      value_cache = (sel_cache[sel.to_sym] ||= _make_cache_hash(type))

      if value = value_cache[key]
        return value
      else
        # Begin searching for matching content.
        # Trap errors from backend.
        begin
          sel.enumerate.each do | s |
            if value = _get_with_sel(type, key, s, sel, sel_cache)
              # Rebind value with requested selector.
              value = type.coerce_value_to_selector value, sel
 
              # Fill fallback cache.
              fallback_sel_cache = (@fallback_cache[type] ||= { })
              fallback_value_cache = (fallback_sel_cache[sel.to_sym] ||= { })
              fallback_value_cache[key] = value
              
              # $stderr.puts "  get #{type.name.inspect} #{key.inspect} #{s.to_a.inspect} => #{value}"
              return value_cache[key] = value
            end
          end

        rescue ::Exception => err
          # Trap error from backend.
          log(:error) { "error #{err.inspect}\n  #{err.backtrace.join("\n  ")}" }
          error = err
          # Fall-through to fallback cache.
        end
      end
      
      # Try fallback cache.
      fallback_sel_cache = (@fallback_cache[type] ||= { })
      fallback_value_cache = (fallback_sel_cache[sel.to_sym] ||= { })
      if value = fallback_value_cache[key]
        log(:warn) { "resorting to fallback cache #{type.name.inspect} key #{key.inspect}" }
        # Fill value cache from fallback cache.
        value_cache[key] = value
      else
        # Reraise error if trapped from backend.
        # Otherwise assume that content is unknown.
        if error
          raise error
        else
          raise Error::Unknown, "type #{type.name.inspect} key #{key.inspect} selector #{sel.inspect}"
        end
      end

      value

    ensure
      @selector = selector_save
    end


    # Same as:
    #
    #   Contenter::Api.current.get(...)
    #
    def self.get *args
      current.get(*args)
    end
    

    # Returns nil if Error::UnknownContent is thrown during #get().
    def get_or_nil(*args)
      get(*args)
    rescue Error::Unknown
      nil
    end


    # Same as:
    #
    #   Contenter::Api.current.get_or_nil(...)
    #
    def self.get_or_nil *args
      current.get_or_nil(*args)
    end


    def fix_selector sel
      if sel
        sel = Selector.coerce(sel)
        sel = sel.default_from(selector)
      else
        # Default selector to current Selector.
        sel = selector
      end

      sel
    end


    # Returns a list of content keys that match the search options and the selector.
    def enumerate type, opts = nil, sel = nil
      # Error thrown from backend.
      error = nil

      sel = sel && fix_selector(sel)

      # Keep current selector for recursion by StringTemplate#t.
      selector_save = @selector
      @selector = sel

      # Convert type to a Api::Type.
      type = coerce_type(type)

      # Ask the Store to enumerate all the keys.
      value = type.store.enumerate type, opts, sel

      # Return the result.
      value
    ensure
      @selector = selector_save
    end


    # Same as:
    #
    #   Contenter::Api.current.enumerate(...)
    #
    def self.enumerate *args
      current.enumerate(*args)
    end


    ##################################################################
    # Internals
    #


    # Internal method: called from #get.
    def _get_with_sel type, key, sel, requested_sel, sel_cache
      value_cache = (sel_cache[sel.to_sym] ||= _make_cache_hash(type))
      unless value = value_cache[key]
        # $stderr.puts "  _get_with_sel(#{type.name.inspect}, #{key.inspect}, #{sel.to_a.inspect}, #{requested_sel.inspect})"
        # Get raw value from Store.
        value = type.store.get(type, key, sel)

        # If available,
        if value
          # Ask Type to convert raw value to cacheable value.
          value = type.construct_value(value, key, sel)
          
          # $stderr.puts "    => #{value.inspect}"
          value_cache[key] = value
        end
      end
      value
    end


    # Creates a caching hash for a particular content key.
    def _make_cache_hash type
      config = _get_config
      config &&= config[:cache]

      h = HashTtl.new
      h.ttl      = cache_ttl ||
        (config && 
         (
          ((x = config[type.name]) && x[:ttl]) || 
          ((x = config[nil]) && x[:ttl])
          )) ||
        300 # 5 minutes
      h.ttl_bias = cache_ttl_bias ||
        (config && 
         (
          ((x = config[type.name]) && x[:ttl_bias]) || 
          ((x = config[nil]) && x[:ttl_bias])
          )) ||
        100 # 100 second random bias

      h
    end

    def _get_config
      config = @config
      config = config.call if Proc === config
      config
    end

    # Forces a flush of any cached content values.
    def flush_cache!
      @cache = { }
    end

    def flush_fallback_cache!
      @fallback_cache.clear
    end

    # Checks cache for invalid
    def invalidate_cache! now = nil
      now ||= Time.now
      expired = 0
      @cache.each do | type, sel_cache |
        # Ask each content type to invalidate its internal cache.
        type.invalidate_cache! now

        # Ask each content store to invalidate its internal cache.
        type.store.invalidate_cache! now

        # Invalidate each selector's frontend cache.
        sel_cache.each do | sel, value_cache |
          expired += value_cache.check_time_to_live!(now).size
          # $stderr.puts "expired #{type.inspect} #{sel} #{expired.inspect}"
        end
      end
      expired
    end


    # Explicitly register a Contenter::Api::Type object for
    # a content type Symbol.
    def register_type name, obj
      raise ArgumentError, "expected Symbol, given #{name.inspect}" unless Symbol === name
      @type[name] = obj
      obj.api = self
    end


    # Coerces a content type name (Symbol) to its Api::Type object.
    def coerce_type name
      raise ArgumentError, "expected Symbol, given #{name.inspect}" unless Symbol === name
      @type[name] ||= 
        (t = Type.coerce(name)) &&
        (t.api = self) &&
        t
    end

    alias :type :coerce_type


    # Explicitly register a Contenter::Api::Store object for
    # a content store Symbol.
    def register_store name, obj
      raise ArgumentError, "expected Symbol, given #{name.inspect}" unless Symbol === name
      @store[name] = obj
    end


    # Coerces a content store name (Symbol) to its Api::Store object.
    def coerce_store name
      raise ArgumentError, "expected Symbol, given #{name.inspect}" unless Symbol === name
      @store[name] ||= 
        (s = Store.coerce(name)) &&
        (s.api = self) &&
        s
    end

    alias :store :coerce_store
   
    
    # Same as current.type.
    def self.type(x)
      current.type(x)
    end


    # Same as current.store
    def self.store(x)
      current.store(x)
    end


    # Preload all registered content type content data.
    # Call this before entering main processing loop.
    def preload!
      Type.all_names.each { | name | type(name).preload! }
    end

    # Reload all registered content type content data.
    def reload!
      @cache.clear
      Type.all_names.each { | name | type(name).reload! }
    end


    # Returns a Hash of stats.
    def stats
      result = { }
      cache_entries = 0
      cache_entries += @cache.size
      @cache.each do | type, sel_c |
        count = sel_c.size
        sel_c.each do | sel, key_c |
          count += key_c.size
        end
        ((result[:type] ||= { })[type.to_sym] ||= { })[:cache_entries] = count
        cache_entries += count
      end
      result[:cache_entries] = cache_entries

      result
    end

  end # class
end # module


require 'contenter/error'
require 'contenter/api/selector'
require 'contenter/api/type'
require 'contenter/api/store'
require 'contenter/api/hash_ttl'

require 'contenter/api/log'

module Contenter
  class Api
    include Log
  end
end

