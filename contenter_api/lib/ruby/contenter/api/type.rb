require 'contenter/api'

require 'contenter/api/log'

module Contenter
  class Api
    # Represents a particular content type.
    # Responsible for transforming raw content data from a content Store,
    # into an object usable by an application.
    class Type
      include Log

      # The name of this content type.
      attr_reader :name
      alias :to_sym :name

      # The Contenter::Api object that created this type.
      attr_accessor :api

      # The Store for this type.
      attr_accessor :store


      @@content_type_to_class ||= { }

      # Register this class for this content type name.
      def self.register_content_type name
        return name.map { register_content_type x } if Enumerable === name

        name = name.to_sym

        if (cls = @@content_type_to_class[name]) && cls != self
          raise Error::Configuration, "class #{cls.inspect} already registered for content type #{name.inspect}"
        end

        @@content_type_to_class[name] = self
      end


      def self.all_names
        @@content_type_to_class.keys
      end


      # Coerces a content type name to a Contenter::Api::Type object.
      def self.coerce type
        case type
        when nil, self
          type
        when Symbol
          # Get the content type class.
          unless cls = @@content_type_to_class[type]
            raise Error::Configuration, "class not registered for content type #{type.inspect}"
          end

          # Create the content type backend.
          obj = 
            begin
              cls.new(:name => type)
            rescue Exception => err
              raise ArgumentError, "Cannot create content type object for content type #{type.inspect}\n#{err.inspect}"
            end

          # Give the content type backend an opportunity
          # to preload content.
          obj.preload!

          obj
        else
          raise ArgumentError, "expected #{self}, Symbol or nil"
        end
      end


      def initialize opts
        @name = opts[:name]
        @store = opts[:store]
        raise Error::Configuration, "name not defined" unless @name
      end


      # Coerces a content key to a Symbol.
      # Subclasses can override this method to map
      # composite keys to simple immutable, atomic keys.
      def coerce_key key
        key
      end


      # Coerces a content value to use a given selector.
      # Support for StringTemplate#t.
      # Subclasses may override this.
      def coerce_value_to_selector value, selector
        value
      end


      # Coerces raw content from a content store to an object
      # representing the content type.
      # Subclasses may override this.
      def construct_value value, key, selector
        value
      end


      # Invalidate any cached content if out of date.
      # Subclasses may override this.
      def invalidate_cache! now
      end


      # Preload any cachable content.
      # This should *not* load everything if the content set is very large.
      # Subclasses may override this, but should call super.
      def preload!
        @store.preload! if @store
        self
      end

      # Reload any cachable content.
      # This should *not* load everything if the content set is very large.
      # Subclasses may override this, but should call super.
      def reload!
        @store.reload! if @store
        self
      end

    end # class
  end # class
end # module

