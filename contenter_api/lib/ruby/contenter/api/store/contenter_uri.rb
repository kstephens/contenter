require 'contenter/api/store'

require 'contenter/api/content'
require 'contenter/api/parse'

require 'contenter/uri'

module Contenter
  class Api
    class Store
      # A content store for using Contenter GUI or proxy as a content store.
      #
      # Will typically request a cannonical URI for content.
      #
      # Thus a request for:
      #
      #   get(:phrase, :some_key, { :language => :en, :country => :US, :brand => :brand1, :application => :app })
      #
      # would request:
      #   
      #   http://contenter.somedomain.com/api/dump?application=app&brand=brand1&content_key=some_key&content_type=phrase&country=US&language=en
      #
      # then parse the resultant YAML for the content.
      #
      class ContenterUri < self
        include Contenter::Api::Parse

        register_content_store :contenter_uri

        # The base URI for content requests
        # e.g.: http://contenter.somedomain.com/api/dump
        attr_accessor :base_uri

        # Additional URI query parameters
        # e.g.: content_status=approved|released
        attr_accessor :override_uri_params


        def initialize opts
          @base_uri = opts[:base_uri]
          @override_uri_params = opts[:override_uri_params]
          super
          @override_uri_params ||= { }
          @content_uri = { } # cache
        end


        # Interface to API#get.
        #
        # Returns a Content or nil.
        def get(type, key, sel)
          raise TypeError unless Symbol === type
          raise TypeError unless Symbol === key
          raise TypeError unless Selector === sel

          value = nil

          log(:debug) { "  get(type = #{type.inspect}, key = #{key.inspect}, sel = #{sel.inspect})" }

          value = get_content(type, key, sel)

          value

        rescue OpenURI::HTTPError, Errno::ENOENT => err # Errno::ENOENT if using "file://" protocol.
          value = nil

        ensure
          log(:debug) { "    => #{value.inspect}" } if value
        end


        # Interface to API#enumerate.
        #
        # Returns Array of [ Key, Source Selector ]
        def enumerate(type, opts, selector)
          raise TypeError unless Symbol === type
 
          result = get_enumerate(type, opts, selector)
          
          result
        end



        ##############################################################
        # Implementation
        #
        
        # Returns single Content object.
        def get_content type, key, selector
          uri = content_uri(type, key, selector)
          content = request_uri_content!(uri)
          content = parse_yml_array(content, uri)
          raise Error::Input, "get_content: #{uri}: Expected only 1 content record, given #{content.size}" if content.size > 1
          content.first
        end

        def content_uri type, key, selector
          x = (@content_uri[type] ||= { })
          x = (x[selector.to_sym] ||= { })
          x = (x[key] ||= "#{base_uri}?#{content_uri_params(type, key, selector)}".freeze)
          # $stderr.puts "base_uri = #{base_uri.inspect}"
          # $stderr.puts "content_uri = #{x.inspect}"
          x
        end

        # Constructs a cannonical URI.
        def content_uri_params type, key, selector
          uri_params = selector.uri_params.dup
          uri_params[:content_type] = type
          uri_params[:content_key] = key
          uri_params.update(override_uri_params)
          Content.cannonical_uri_query_params(uri_params)
        end
        
        # Returns single Content object.
        def get_enumerate type, opts, selector
          uri = "#{base_uri}?#{enumerate_uri(type, opts, selector)}"
          content = request_uri_content!(uri)
          hashes = parse_yml_raw(content, uri)
          hashes.map! do | h |
            [ h[:content_key], h[:selector] ]
          end
        end

        def enumerate_uri type, opts, selector
          opts ||= EMPTY_HASH
          columns = Content::AXIS_NAMES + [ :content_key, :content_type ]
          uri_params = {
            :content_type => type,
            :columns => columns.map{|x| x.to_s}.sort.join(','), # cannonical
            :unique => 1,
          }
          uri_params.update(selector.to_hash) if selector
          opts.to_hash.each do | k, v |
            uri_params[k] = v if v
          end
          uri_params.update(override_uri_params)
          Content.cannonical_uri_query_params(uri_params)
        end

        def request_uri_content! uri
          log(:debug) { "request_uri_content! #{uri.inspect}" }
          with_timeout do
            URI.parse(uri.to_s).read
          end
        end
        
      end # class
    end # class
  end # class
end # module

