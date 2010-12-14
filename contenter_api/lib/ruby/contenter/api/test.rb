require 'contenter/api'

module Contenter
  class Api
    module Test
      def setup!
        Contenter::Api.configure!
        Contenter::Api::Selector.default = {
          :application => :test,
          :brand => :test,
          :country => :US,
          :language => :en,
        }
      end
      extend self
    end # module Test

    class Type
      # A content type for test content.
      class Test < self
        class Error < ::Exception; end

        register_content_type :test

      end
    end

    class Store
      # A content store for test content.
      class Test < self
        attr_accessor :data

        attr_accessor :force_error

        attr_accessor :error_message

        def get(type, key, sel)
          @error_message = nil
          if @force_error
            @error_message = "key #{key.inspect} sel #{sel.inspect}"
            raise @force_error, @error_message
          end
          raise "@data not initialized, #preload! not called" unless @data

          (x = @data[sel.language]) &&
            x[key]
        end

        def preload!
          @data = {
            :en => {
              :hello => 'hello',
            },
            :es => {
              :hello => 'hola',
            },
          } 
        end # class

        def reload!
          super
        end
      end # class
    end # class
  end # class
end # module

