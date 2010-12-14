require 'contenter/api/type'

require 'contenter/api/string_template'


module Contenter
  class Api
    class Type
      #
      # Returns a Contenter::Api::StringTemplate for
      # interpolation with using StringTemplate#% operator.
      class Phrase < self
        register_content_type :phrase

        # Construct raw value from Store.
        #
        # Returns a Contenter::Api::StringTemplate object from a Content object.
        #
        def construct_value(value, key, selector)
          # $stderr.puts "construct_value(#{value.inspect}, #{key.inspect}, #{selector.inspect})"
          StringTemplate.new(value, api)
        end

        # Rebinds value to the requested selector.
        def coerce_value_to_selector value, selector
          if value._selector.to_sym != selector.to_sym
            # $stderr.puts "coerce_value_to_selector(#{value.inspect}, #{selector.inspect})"
            value = value.dup
            value._selector = selector
          end
          value
        end
      end # class
    end # class
  end # class
end # module

