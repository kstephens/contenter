require 'contenter/api'

require 'contenter/hash'
require 'cgi'

module Contenter
class Api
  # Represents Content over the wire.
  class Content
    AXIS_NAMES = [ :language, :country, :brand, :application, ].freeze
    
    OTHER_ATTRIBUTES = [ :uuid, :version, :content_type, :content_key, :content_key_uuid, :content_status, :updater, :creator, :filename, :md5sum, :data ].freeze
    
    ATTRIBUTES = (OTHER_ATTRIBUTES + [ :mime_type ] + AXIS_NAMES).freeze

    NON_SYMBOL_ATTRIBUTES = [ :uuid, :version, :content_key_uuid, :filename, :md5sum, :data ].freeze

    SYMBOL_ATTRIBUTES = (ATTRIBUTES - NON_SYMBOL_ATTRIBUTES).freeze

    IDENTITY_ATTRIBUTES = ([ :content_key, :content_type ] + AXIS_NAMES).freeze

    def self.contenter_base_uri x = nil
      @@contenter_base_uri = x if x
      Thread.current[:'Contenter::Api::Content.contenter_base_uri'] ||
        @@contenter_base_uri ||= 'http://localhost:3000'
    end

    def self.axis_names
      AXIS_NAMES
    end
    

    def self.cannonical_uri_query_params(params)
      params.
        keys.
        sort_by { | k | k.to_s }.
        map { | k | "#{k}=#{CGI.escape((params[k] || UNDERSCORE).to_s)}" }.
        join('&')
    end
    
    
    ###############################################
    
    
    def initialize opts = EMPTY_HASH
      @opts = opts.freeze
    end
    
    
    AXIS_NAMES.each do | name |
      class_eval(<<"END", __FILE__, __LINE__)
def #{name}
  (sel = @opts[:selector]) ? sel.#{name} : @opts[#{name.inspect}]
end
END
    end

    OTHER_ATTRIBUTES.each do | name |
      class_eval(<<"END", __FILE__, __LINE__)
def #{name}
  @opts[#{name.inspect}]
end
END
    end

    def method_missing sel, *args
      if args.empty? && sel.to_s =~ /\A(\w+)\Z/ && ! block_given?
        Content.class_eval(<<"END", __FILE__, __LINE__)
def #{sel}
  @opts[#{sel.inspect}]
end
END
        @opts[sel.to_sym]
      else
        super
      end
    end

    def to_hash
      @to_hash ||= 
        ATTRIBUTES.
        inject({ }) { | h, k | h[k] = send(k); h }.
        freeze
    end

    def cannonical_uri_query_params(opts = nil)
      if opts
        Content.cannonical_uri_query_params(to_hash.project(IDENTITY_ATTRIBUTES).merge(opts)).freeze
      else
        @cannonical_uri_query_params ||=
          Content.cannonical_uri_query_params(to_hash.project(IDENTITY_ATTRIBUTES)).freeze
      end
    end

    def cannonical_uri
      @cannonical_uri ||=
        begin
          x = "#{Content.contenter_base_uri}/contents/show/#{uuid}"
          x << "?version=#{version}" if version
          x.freeze
        end
    end

    A_CLOSE = '</a>'.freeze

    # Returns html annotated with link(s) to the cannonical path to a cms for
    # this content.
    def html_href(html = nil, target = nil)
      html ||= data
      target ||= 'contenter_cms'

      uri = cannonical_uri
      a_href = %Q{<a href=#{uri.inspect} class="contenter_cms" target="#{target}">}

      out = a_href.dup

      a_href = "#{A_CLOSE}#{a_href}"
      out << html.gsub(/(<[^>]*a\b[^>]*>)/i) do | x |
        case x
        when /<\s*\/\s*a\s*>/i
          a_href
        else
          "#{A_CLOSE}#{x}"
        end
      end

      # $stderr.puts out
      out.sub!(/#{Regexp.escape(a_href)}\Z/, '')

      out << A_CLOSE 

      out
    end

  end # class
end # class
end # module


