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

    def self.html_href_opts x = nil
      @@html_href_opts = x if x
      Thread.current[:'Contenter::Api::Content.html_href_opts'] ||
        @@html_href_opts ||= EMPTY_HASH
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
      raise Error, "@opts[:content_key]" unless @opts[:content_key]
    end
    
    
    AXIS_NAMES.each do | name |
      class_eval(<<"END", __FILE__, __LINE__)
def #{name}
  (sel = @opts[:selector]) ? sel.#{name} : @opts[#{name.inspect}]
end
END
    end

    def content_key_string
      @content_key_string ||=
        content_key.to_s.freeze
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


    # Returns HTML annotated with link(s) to the cannonical path to the contenter CMS for
    # this content.
    def html_href(html = nil, opts = nil)
      opts ||= EMPTY_HASH
      html ||= data
      
      opts = Content.html_href_opts.merge(opts)

      tag = opts[:tag] || 'span'

      case opts[:mode]
      when :text
        open_tag = "[[#{tag}:#{uuid}]]"
        close_tag = "[[#{tag}]]"
      else
        cls = opts[:class] || 'contenter_cms_link'
        target = opts[:target]
        uri = cannonical_uri
        open_tag = %Q{<#{tag} class="#{cls}" title="cms: #{CGI.escapeHTML(content_key_string)}" href="#{uri}"}
        if target
          open_tag << %Q{ target="#{target}"}
          open_tag << %Q{ onclick="window.open(this.href, '#{target}', 'left=10, top=10, height=400, width=800, menubar=1, location=1, toolbar=1, scrollbars=1, status=1, resizable=1'); return false;"} if opts[:force_window]
        end
        open_tag << ">"
        close_tag = "</#{tag}>"
      end

      case opts[:mode]
      when :text
        out = open_tag
        out << html
        out << close_tag

      when nil, :start_link
        out = open_tag
        out << (opts[:link_text] || '[C]')
        out << close_tag
        out << html

      when :spans
        out = open_tag.dup
        
        out << html.gsub(%r{(<\s*/?\s*([a-z]+)[^>]*>)}i) do | x |
          "#{close_tag}#{x}#{open_tag}"
        end
        
        out << close_tag

        # Filter out empty spans.
        out.gsub!("#{open_tag}#{close_tag}", '')
      end

=begin
      $stderr.puts "in=\n#{html}"
      $stderr.puts "out=\n#{out}"
=end
      out
    end

    def html_href_cached
      @html_href_cached ||=
        html_href.freeze
    end

  end # class
end # class
end # module


