require 'contenter/api'

require 'contenter/api/log'

module Contenter
  class Api
    # Base class for raw content stores.
    # Subclasses provide interfaces to retrieve raw content.
    class Store
      include Log

      # The name of this content store.
      attr_reader :name
      alias :to_sym :name

      # The Contenter::Api object for this store.
      attr_accessor :api

      # Raise a Contenter::Error::Timeout after #timeout seconds. 
      # Can be a Proc.
      attr_accessor :timeout

      @@content_store_to_class ||= { }

      # Register this class for this content store name.
      def self.register_content_store name
        return name.map { register_content_store x } if Enumerable === name

        name = name.to_sym

        if cls = @@content_store_to_class[name]
          raise Error::Configuration, "class #{cls.inspect} already registered for content store #{name.inspect}"
        end

        @@content_store_to_class[name] = self
      end


      def self.all_names
        @@content_store_to_class.keys
      end


      # Coerces a content store name to a Contenter::Api::Store object.
      def self.coerce store
        case store
        when nil, self
          store
        when Symbol
          # Get the content store class.
          unless cls = @@content_store_to_class[store]
            raise Error::Configuration, "class not registered for content store #{store.inspect}"
          end

          # Create the content store backend.
          obj = 
            begin
              cls.new(:name => store)
            rescue Exception => err
              raise ArgumentError, "Cannot create content store object for content store #{store.inspect}\n#{err.inspect}"
            end

          obj
        else
          raise ArgumentError, "expected #{self}, Symbol or nil"
        end
      end


      def initialize opts
        @name = opts[:name]
        @timeout = opts[:timeout]
        raise Error::Configuration, "name not defined" unless @name
      end


      # Main interface to Contenter::Api#get.
      # Subclasses must override this.
      def get(type, key, sel)
        raise ArgumentError unless Type === type
        raise ArgumentError unless Selector === sel
        raise ArgumentError unless Symbol === key
        raise Error::SubclassResponsibility
      end


      # Main interface to Contenter::Api#enumerate.
      # Subclasses must override this.
      def enumerate(type, opts)
        raise Error::SubclassResponsibility
      end


      # Invalidate any cached content if out of date.
      # Subclasses may override this.
      def invalidate_cache! now
      end


      # Preload any cachable content.
      # This should *not* load everything if the content set is very large.
      # Subclasses may override this, but should call super.
      def preload!
      end

      # Reload any cachable content.
      # Subclasses may override this, but should call super.
      def reload!
      end

      # Subclasses
      def with_timeout timeout = nil
        timeout ||= self.timeout
        timeout = timeout.call if Proc === timeout
        if timeout && timeout > 0
          ::Timeout.timeout(timeout, Contenter::Error::Timeout) do
            yield
          end
        else
          yield
        end
      end
      protected :with_timeout

    end # class
  end # class
end # module

