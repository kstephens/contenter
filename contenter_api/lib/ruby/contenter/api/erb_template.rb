require 'contenter/api/type'

require 'erb'


module Contenter
  class Api
    # Basic wrapper around ERB for content type data.
    # Specific content types can subclass this if they have
    # ERB template data.
    class ERBTemplate
      attr_accessor :content, :template, :key, :selector
      
      def initialize content, api = nil
        @content = content
        @template = content.data
        @key = content.content_key
        @selector = content.selector
        @template.freeze
      end
      
      
      # Returns the ERB.
      def erb_template
        @erb_template ||= ERB.new(template)
      end
      
      
      # Renders template with given binding.
      def result b
        erb_template.result(b)
      end
      
      
      def inspect
        "#<#{self.class} #{@key.inspect} #{@selector.inspect}>"
      end
      
      
      def to_s
        @template
      end
      
      
      # Provide global configuration data to the template.
      def config
        raise Error::SubclassResponsibility
      end
      
      
      ####################################################3
      # Preview support.
      #
      
      def result_preview(data = nil)
        Preview.new(self).__result(data)
      end
      
      
      # Class to create a binding for render_preview.
      class Preview
        def initialize ct
          @_template = ct
          @_data = EMPTY_HASH
        end
        
        
        # Called from ContractTemplate#render_preview.
        # Creates closed-over binding via method_missing.
        def __result(data = nil)
          data ||= EMPTY_HASH
          @_data = data
          @_template.render(binding)
        end
        
        
        def method_missing sel, *args
          if (s = sel.to_s) =~ /^[a-z0-9_]+$/ && ! block_given?
            case
            when @_data.key?(s)
              @_data[s]
            when s == 'config'
              @_template.send(sel, *args)
            else                
              @_template.config.preview.data.send(sel, *args)
            end
          else
            super
          end
        end
      end
      
    end # class
    
end # class
end # module

