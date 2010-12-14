require 'contenter/api'

require 'contenter/api/content'

module Contenter
  # Interface to multiple content types.
  class Api

    # Selects a Api resource by:
    #
    #   application
    #   brand
    #   country
    #   language
    #
    # Selector instances are cached.  Use:
    #
    #   Contenter::Api::Selector.coerce(:application => :myapp, :brand => :XYZ, :country => :US, :language => :en)
    # 
    # or
    #
    #   Contenter::Api::Selector[:myapp, :XYZ, :US, :en]
    #
    class Selector
      AXIES = [ :application, :brand, :country, :language ].freeze
      GETTERS = AXIES.freeze
      SETTERS = { } 
      GETTERS.each do | a |
        SETTERS[a] = "#{a}=".to_sym
      end
      SETTERS.freeze

      # See coerce().
      @@instance_cache ||= { }

      attr_accessor *GETTERS

      # Returns a Selector based on application, brand, country, language.
      def self.[](a, b, c, l)
        coerce(:application => a, :brand => b, :country => c, :language => l)
      end


      # Returns a Hash representation of this Selector.
      def to_hash
        @to_hash ||=
        {
          :application => @application,
          :brand       => @brand,
          :country     => @country,
          :language    => @language,
        }.freeze
      end


      # Returns a Array representation of this Selector.
      def to_a
        @to_a ||=
          begin
            GETTERS.map{ | g | send(g) }.freeze
          end
      end


      # Returns a String representation of this Selector.
      # Sutable for a Hash key.
      def to_s
        @to_s ||=
          "#{self.class}#{to_a.inspect}".freeze
      end


      # Returns a Symbol representation of this Selector.
      # This is used for caches.
      def to_sym 
        @to_sym ||=
          to_s.to_sym
      end

      
      # Returns a Selector with all nils replaced with
      # values from sel.
      def default_from sel
        if sel && to_a.any? { | x | x.nil? }
          h = to_hash.dup
          sel.to_hash.each do | k, v |
            h[k] ||= v
          end
          self.class.coerce(h)
        else
          self
        end
      end


      # Same as to_s.
      def inspect
        to_s.dup
      end


      # Same as to_hash but replaces :_ for nil values.
      def uri_params
        @uri_params ||=
          begin
            h = self.to_hash.dup
            h.each { | k, v | h[k] = :_ unless v }
            h.freeze
          end
      end

      
      ################################################################
      # Configuration
      #

      # Returns the environment-local default Selector.
      def self.environment
        @@environment ||=
          coerce(GETTERS.inject({ }){ | h, g | 
                   h[g] = (x = ENV["CONTENTER_#{g.to_s.upcase}"]) ? x.to_sym : nil
                   h
                 })
      end


      ################################################################
      # Default instance (process-specific)
      #

      @@default = nil
      # Returns the Process-local default Selector.
      def self.default
        @@default
      end

      # Sets the Process-local default Selector.
      def self.default= x
        @@default = coerce(x)
      end

      def make_default!
        self.class.default = self
      end


      ################################################################
      # Current instance (thread-specific)
      #

      # Gets the Thread-local Selector or the Process default Selector.
      def self.current
        Thread.current[:'Contenter::Api::Selector.current'] || 
          default
      end


      # Sets the Thread local Selector.
      def self.current= x
        Thread.current[:'Contenter::Api::Selector.current'] = coerce(x)
      end


      # Updates Selector.current with a new Selector object
      # that inherites from Selector.current and
      # then yields to a block.
      #
      # Restores the previous Selector.current after yielding to block.
      #
      # If block is not given, new selector becomes current.
      def self.with(options = EMPTY_HASH)
        current_save = self.current
        
        # Overlay our options on the current Selectors "options" as expressed as a Hash.
        instance = self.coerce(options).default_from(self.current)
        self.current = instance
        
        if block_given?
          begin
            yield(instance)
          ensure
            self.current = current_save
          end
        else
          instance
        end
      end
      
      
      # Coerces to a Selector.
      # Will use an instance_cache.
      def self.coerce sel
        case sel
        when nil
          return sel
        when Selector
        when Hash
          sel = new(sel)
        else
          raise ArgumentError, 'expected Selector, Hash or nil'
        end
        @@instance_cache[sel.to_sym] ||=
          sel
      end

      
      def initialize options = EMPTY_HASH
        options.each do | k, v |
          send("#{k}=", v) if AXIES.include?(k)
        end
      end
      
   
      # Enumerates all valid combinations of
      # attributes valid for searching content
      # sources.
      #
      # Duplicate Selectors
      # are removed.
      def enumerate c = nil
        c ||= self.class.current
  
        (@enumerate ||= { })[c.to_sym] ||=
          begin
            d = self.class.default

            # $stderr.puts "  #{self.to_a.inspect}"
            # $stderr.puts "  #{d.to_a.inspect}"

            tuples = [ ]

            # Create enumeration search axies.
            le = enumerate_axis :language, c, d
            ce = enumerate_axis :country, c, d
            be = enumerate_axis :brand, c, d
            ae = enumerate_axis :application, c, d

            le.each do | l |
              ce.each do | c |
                be.each do | b |
                  ae.each do | a |
                    tuples << [ a, b, c, l ]
                  end
                end
              end
            end
            tuples.uniq!

            tuples = tuples.map do | tuple |
              # $stderr.puts "    #{tuple.inspect}"

              self.class.coerce(:application => tuple[0],
                                :brand       => tuple[1],
                                :country     => tuple[2],
                                :language    => tuple[3]
                                )
            end

            tuples.freeze

            tuples
          end
      end


      # Returns an enumeration of a selector axis that prioritizes self, current and default Selectors.
      # Last entry is always nil.
      def enumerate_axis axis, c, d
        l = [ send(axis), c.send(axis), d.send(axis) ]
        l.compact!
        l << nil
        l.uniq!
        l
      end


      # Configures entire system.
      # Should be done before first Selector is enumerated.
      def self.configure!
        # Must do this before default=
        environment

        # Default to en_US.
        coerce(:language => :en, :country => :US).make_default!
      end

    end # class

  end # module
end # module

