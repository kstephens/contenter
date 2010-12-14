require 'contenter/api'

module Contenter
  class Api

    # Defines a content StringTemplate used for phrase content.
    #
    # Specified as a string.
    #
    # Syntax:
    #
    #   {{{param_expr}}}
    #
    # param_expr is evaluated by #% and #to_s operators.
    #
    #   <{{early_expr}}>
    #
    # early_expr is evaluated before parameter substition.
    #
    class StringTemplate
      # Reference to Contenter::Api object.
      attr_accessor :_api

      # Reference to Contenter::Api::Selector object which
      # specifies the localization
      # context in which this template was requested from.
      attr_accessor :_selector

      # Reference to Content::Api::Content object.
      attr_accessor :_content

      def initialize(content, api = nil)
        @_content = content || raise(ArgumentError, "no content")
        @key = content.content_key || raise(ArgumentError, "no key")
        @key.freeze
        template = content.data
        @template = template
        @template.freeze
        @_selector = content.selector
        @_api = api
        @_format_method = nil
        @_has_parameters = nil
        @arguments = EMPTY_HASH
      end


      # Parses template to create a Ruby expression
      # that can be evaluated to create
      # a singleton method for _format().
      def _format_method
        return @_format_method if @_format_method

        arguments_type = ::Hash
        @_has_parameters = false

        # RANT RANT RANT:
        # THIS CODE DOES NOT WORK.
        # there is a bug in the Ruby parser in some cases.
        # In this object:
        #   instance_eval("t :foo")
        # cannot parse :foo
        # However it works fine in irb and ruby -e.
        #
        # kurt@cashnetusa.com 2009/01/08
=begin
        # Handle early subsititions.
        @_template = @template.gsub(/\<\{\{(.*?)\}\}\>/) do | m |
          expr = $1
          # expr = "(#{expr}).to_s"
          expr = "\n#{expr}\n"
          expr = "begin#{expr}end"
          #expr = ";nil; (#{expr});"
          # expr = "lambda { || #{expr}; }.call"
          $stderr.puts "expr = #{expr}"
          #Contenter::Api::Selector.with(@_selector) do
            result = instance_eval(expr).to_s
          #end
          # $stderr.puts "result = #{result.inspect}"
          result
        end
=end
        @_template ||= @template
        @_template = @template if @_template == @template
        @_template.freeze

        parameter_offset = -1
        p = @_template
        t = "'"
        until p.empty?
          case
          # Escape string delimiters.
          when m = /\A([\\'])/.match(p)
            t << '\\' + m[1]

            # Parameter subsititutions.
          when m = /\A(\{\{\{(.*?)\}\}\})/.match(p)
            t << '\' << (' << m[2] << ').to_s << \''
            @_has_parameters = true

            # "early" subsititutions.
            # SEE RANT ABOVE.
          when m = /\A(\<\{\{(.*?)\}\}\>)/.match(p)
            t << '\' << (' << m[2] << ').to_s << \''
            @_has_parameters = true

          else
            t << p[0 .. 0]
            p = p[1 .. -1]
            
          end
          
          p = m.post_match if m
        end
        t << "'"

        # STDERR.puts "template #{template.inspect} => #{t.inspect}"

        # Decide on arguments defaults depending on the template substitutions.
        @arguments_default = 
        case arguments_type
        when ::Array
          EMPTY_ARRAY
        when ::Hash
          EMPTY_HASH
        else
          EMPTY_HASH
        end
        @arguments = @arguments_default

        # $stderr.puts "arguments = #{@arguments.inspect}"
        # $stderr.puts "arguments_default = #{@arguments_default.inspect}"
        
        # Define a __format singleton method.
        # TODO: Not thread-safe.
        if @_has_parameters
          t = <<-"END"
            def self.__format(args)
              arguments_save = @arguments
              @arguments = args || @arguments_default
              #{t}
            ensure
              @arguments = arguments_save
            end
END
        else
          t = <<-"END"
            def self.__format(args)
              @_template
            end
END
        end

        # $stderr.puts "@_format =\n#{t}"

        @_format_method = t.freeze

      rescue Exception => err
        new_err = err.class.new("#{err} in #{self.inspect}:\n  #{err.backtrace * "\n  "}")
        raise new_err
      end


      # Returns true if template has a {{{...}}} parameter.
      def _has_parameters?
        _format_method if @_has_parameters.nil?
        @_has_parameters
      end


      # Handle for self.clone.__format.
      # Redefines __format() dynamically based on the template string.
      def __format(params)
        # Define singleton method.
        instance_eval(_format_method, __FILE__, __LINE__)
        # Delegate to singleton method.
        __format(params)
      end


      # Calls __format with the template parameters.
      def _format(params)
        case params
        when Array, Hash, nil
        else
          $stderr.puts "#{self.class}: Warning: Use % with Array or Hash arguments instead of #{params.inspect}\n  #{caller.join("\n  ")}"
          params = [ params ]
        end

        __format(params)
      end
      
      
      # See String#to_s.
      #
      # To support translation of non-parameterized localized strings
      # returned from String#t, Symbol#t.
      #
      # to_s returns a frozen String.
      def to_s(params = nil)
        _has_parameters? ? _format(params) : @_template
      end
      

      # Returns the raw template String.
      def _template
        @template
      end
      

      # See String#+.
      def +(x)
        to_s + x.to_s
      end
      
      
      # See String#%.
      alias :% :_format
      
      
      # Loopback to Contenter::Api.current.
      def api
        @_api ||
          Contenter::Api.current
      end


      # Used to embed content substitutions in a content template:
      #
      #   hello_world: "{{{t :hello}}}, <{{t :world}}>"
      #
      # Is equivalent to:
      #
      #   '' << Contenter::Api.get(:phrase, :hello, @_selector).to_s << 
      #     ', ' << 
      #     Contenter::Api.get(:phrase, :world, @_selector).to_s <<
      #
      # This is different from:
      #
      #   "{{{:hello.t}}}"
      #
      # which will load the content based on the current
      # content selector, rather than the same content
      # selector as this content.
      #
      def t phrase_key, opts = nil
        a = api
        a.get(:phrase, 
              phrase_key, 
              opts || 
              @_selector || 
              a.selector
              )
      rescue Exception => err
        new_err = err.class.new("#{err} in #{self.inspect}:\n  #{err.backtrace * "\n  "}")
        raise new_err
      end

      
      def inspect
        "#<#{self.class} #{@key.inspect} #{@template.inspect} #{@_selector}>"
      end
      
      
      # Returns the current parameter argument by name as currently bound by __format.
      def method_missing(sel, *args, &blk)
        # STDERR.puts " @arguments = #{@arguments.inspect} sel = #{sel.inspect}"
        if args.empty? && ! block_given? && @arguments.has_key?(sel = sel.to_sym)
          @arguments[sel]
        else
          super
        end
      rescue Exception => err
        new_err = err.class.new("#{err} in #{self.inspect}:\n  #{err.backtrace * "\n  "}")
        raise new_err
      end
      
    end # class
  end # class
end # module

