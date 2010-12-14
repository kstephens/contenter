module Cabar
  # Common base class for Cabar classes.
  # Handles common stuff, should probably
  # be refactored into a includeable module.
  class Base
    attr_reader :_options

    @@factory = { }

    # Defines the factory object for this Class.
    def self.factory= x
      @@factory[self] = x
    end

    # Returns the factory object for this Class that responds to #new.
    # This defaults to the Class object itself if not specified
    # by #factory=.
    def self.factory
      @@factory[self] ||= self
    end


    def self.attr_accessor_type name, type, constructor = :create_cabar
      self.class_eval <<"END", __FILE__, __LINE__
        def #{name}
          @#{name}
        end
        def #{name}=(x)
          y = x
          case y
          when nil, #{type}
          else
            y = #{type}.#{constructor} y
          end
          @#{name} = y
          # $stderr.puts "\#{self.class}##{name} x = \#{x.inspect} y = \#{y.inspect}"
          x
        end
END
    end

    def initialize opts = EMPTY_HASH
      self._options = opts
    end

    # Convert String keys to Symbol keys.
    def _normalize_options! opts, new_opts = { }
      opts.each do | k, v |
        new_opts[k.to_sym] = v
      end
 
      new_opts
    end

    # Sets @_options with elements from opts.
    # Any setter that match keys are called
    # and the key is deleted from @_options.
    def _options= opts = EMPTY_HASH
      @_options ||= { }

      _normalize_options! opts, @_options

      # $stderr.puts "opts = #{opts.inspect}"
      # $stderr.puts "@_options = #{@_options.inspect}"

      @_options.each do | k, v |
        s = "#{k}="

        if respond_to? s
          @_options.delete(k)
          send s, v
        end
      end

      self
    end


    # dups object and calls deepen_dup!
    # If arguments are given, they are passed
    # to _options!=.
    def dup *args
      x = super()
      x.deepen_dup!
      unless args.empty?
        x._options= *args
      end
      x
    end


    # Deepens any @_option elements.
    # Subclasses may need to override and call super.
    def deepen_dup!
      @_options = @_options.dup
      @_options.each do | k, v |
        case v
        when Hash, Array, String
          @_options[k] = v.dup
        end
      end
      self
    end


    # Returns @_options[sel] if it exists.
    def method_missing sel, *args, &blk
      if args.empty? && 
          ! block_given? &&
          (sel = sel.to_sym) # && @_options.key?(sel)
        #self.class.define_method sel.to_sym do | |
        #  @_options[sel]
        #end
        return @_options[sel]
      end

      super
    end

  end # class

end # module


