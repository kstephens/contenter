require 'contenter/api/store'

require 'contenter/api/parse'

module Contenter
  class Api
    class Store
      # A content store for Contenter Bulk YAML files.
      class ContenterYml < self
        include Contenter::Api::Parse

        register_content_store :contenter_yml

        # The file or array of files content is served from. These are overlayed to build up the hash, with later
        # elements adding to or overriding (but not deleting) previous elements. The scenario this supports is
        # a branch of development where developers manually create an overlay file prior to uploading their new
        # keys/values to the CMS and merging with the main file. New elements may appear or change in the main file
        # and the project branch file will be unaffected.
        attr_accessor :file

        def initialize opts
          @file_cache = { }
          super
          @file = opts[:file]
          @file = @file.split(/:|\s+|\s*,\s*/) if String === @file
        end


        # Interface to Contenter::Api#get.
        #
        # Returns an Array: [ String, Source Selector ] or nil.
        def get(type, key, sel)
          log(:debug) { "  get(type = #{type.inspect}, key = #{key.inspect}, sel = #{sel.inspect})" }

          hash = self.hash
          return nil unless hash

          # Type =>
          value   = hash[type.to_sym]
          # Selector =>
          value &&= value[sel.to_sym]
          # Key =>
          value &&= value[key.to_sym]
          
          log(:debug) { "    => #{value.inspect}" } if value

          value
        end


        # Interface to Contenter::Api#enumerate.
        #
        # Returns Array of [ Key, Source Selector ]
        def enumerate(type, opts, selector)
          type = type.to_sym

          result = [ ]

          h = self.hash
          sel_h = h[type] || EMPTY_HASH
          sel_h.each do | sel, key_h |
            key_h.each do | key, val |
              # Filter by selector.
              next if selector && ! content.get_or_nil(type, key, selector)
              result << val
            end
          end

          result
        end


        # Preload YAML file.
        def preload!
          hash
        end


        # Reload YAML file.
        def reload!
          @hash = nil
          @file_cache.clear
        end


        ##############################################################
        # Implementation
        #

        # Returns the merged Hashes from all files.
        # Hash is [type][selector][key] => Content
        def hash
          unless @hash 
            # If there's only one file, don't bother merging.
            if @file.size == 1
              return @hash = get_file(@file.first)
            end

            @hash = { }
            @file.each do | file |
              get_file(file).each do | type, h1 |
                h1.each do | sel, h2 |
                  h2.each do | key, content |
                    ((@hash[type] ||= { })[sel] ||= { })[key] = content
                  end
                end
              end
            end
          end

          @hash.freeze
        end

        # Returns the file's [type][selector][key] Hash => Content
        # The Hash is cached until the file has changed.
        def get_file file
          (@file_cache[file] ||=
            [ 
             read_yml(file), 
             file, 
             (File.size(file) rescue nil), 
             (File.mtime(file) rescue nil)
            ].freeze
           ).first
        end


        # Returns the current Time.
        def now
          @now || Time.now
        end


        # Called from Contenter::Api#invalidate_cache!
        def invalidate_cache! now = self.now
          invalid_files = [ ]

          @file_cache.each do | file, cache |
            cache_contents, cache_file, cache_size, cache_mtime = *cache 
            file_size = File.size(file) rescue nil
            file_mtime = File.mtime(file) rescue nil
            if file_size != cache_size || file_mtime != cache_mtime
              invalid_files << file
            end
          end

          unless invalid_files.empty?
            @hash = nil # Aggregated data is also invalid.
            invalid_files.each { | k | @file_cache.delete(k) }
          end

          log(:debug) { "  invalid_files = #{invalid_files.inspect}" }

          invalid_files
        end


        # Read YAML file and convert it into
        # a Hash of Symbols to StringTemplate objects.
        def read_yml file
          raise ArgumentError unless String === file

          result = nil

          log(:debug) { "  read_yml #{file.inspect}" }

          # No content for key if file does not exist.
          return EMPTY_HASH unless file && File.exist?(file)

          h = parse_yml_hash(File.read(file), file)

          h.freeze
        end


      end # class
    end # class
  end # class
end # module

