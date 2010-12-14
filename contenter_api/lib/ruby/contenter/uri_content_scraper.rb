require 'contenter'

require 'contenter/error'
require 'contenter/uri'

require 'contenter/api/hash_ttl'

module Contenter
  class UriContentScraper
    # The uri to scrape.
    attr_accessor :uri

    # The root of the uri to scrape.
    attr_accessor :root_uri

    # The leading tag string to find replacements in the #content_raw.
    attr_accessor :replacement_tag

    # A Hash of Symbols mapping to Strings.
    # For every substring in content_raw that matches /#{replacement_tag}(\w+)/
    # replace it with replacements[$1.to_sym].
    attr_accessor :replacements

    def initialize opts = nil
      opts ||= EMPTY_HASH
      opts.each do | k, v |
        send("#{k}=", v)
      end
    end

    def root_uri
      @root_uri ||=
        begin
          u = URI.parse(uri.to_s)
          u.path = ''
          u.to_s
        end
    end

    def content_raw
      @content_raw ||=
        request_uri_content!(uri).freeze
    end
    
    # Content replaced with replacements.
    def content_replaced
      @content_replaced ||=
        begin
          x = content_raw.dup
          x.gsub!(/\b#{replacement_tag}(\w*)\b/) { | m | replacements[$1.to_sym] }
          x.freeze
        end
    end
    
    
    # Translate:
    #
    # <img src="/foo">
    # TO
    # <img src="http://asdf.com/foo">
    #
    # Should also handle embedded JS ".src='something'"
    #
    # <img name="btn_click" src="/dbimg/img1.gif" alt="Click For Cash Apply Now" onmouseover="document.btn_click.src='/dbimg/img1_over.gif';" />"
    def content_html_reroot
      @content_html_reroot ||=
        begin
          x = content_replaced.dup
          x.gsub!(%r{([\s\.](href|src)=[\"\'])(/)}) { | m | $1 + root_uri + $3 }

          # Add <base> tag in the hope that anything missed above
          # will be honored by the brower's interpretation of
          # the <base> tag.
          x.gsub!(%r{<base\s+href=[\'\"][^>]+>}, '')
          x.sub!(%r{(<\s*head\s*>)}) { | m | %Q{#{$1}\n<base href="#{root_uri}/" />} }

          x.freeze
        end
    end


    # A raw URI content cache.
    @@uri_content_cache ||= nil

    def uri_content_cache
      @@uri_content_cache ||= 
        begin
          x = Contenter::Api::HashTtl.new
          x.ttl = 300
          x
        end
    end

    def request_uri_content! uri
      c = uri_content_cache
      c.check_time_to_live!
      c[uri.to_s.dup] ||= 
        request_uri_content_no_cache!(uri).freeze
    end

    # IMPLEMENT ME!!!
    def with_timeout
      yield
    end

    def request_uri_content_no_cache! uri
      # log(:debug) { "request_uri_content! #{uri.inspect}" }
      with_timeout do
        URI.parse(uri.to_s).read
      end
    rescue Exception => err
      raise Contenter::Error, "Cannot read #{uri.to_s.inspect}: #{err.inspect}"
    end
  end
end
