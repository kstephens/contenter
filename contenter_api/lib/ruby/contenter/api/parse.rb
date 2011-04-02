require 'contenter/api'

require 'contenter/api/content'

require 'yaml'
require 'base64'

module Contenter
  class Api
    # Handle common parsing tasks.
    module Parse
      # Parses YAML string into Array of Hash objects.
      # structured as:
      #
      #  [ { :data => ..., :selector => ..., ... } , ... ]
      def parse_yml_raw string, identifier, rows = nil
        rows ||= [ ]

        time_0 = Time.now.to_f
        # Dump memory stats before (and after, below).
        # File.open("/proc/self/statm", "r") { | fh | $stderr.puts fh.read }
        log(:debug) { "Parsing #{identifier}: " }

        result = YAML::load(string)

        # Error if YAML document is not a Hash.
        unless Hash === result
          raise Error::Configuration, "File #{file.inspect} contents is not a Hash YAML"
        end
        
        # $stderr.puts "result.keys = #{result.keys.inspect}"
        
        raise Error::Configuration, "no api_version" unless Integer === result[:api_version]
        contents_columns = result[:contents_columns]
        raise Error::Configuration, "no contents_columns" unless Array === contents_columns
        results = result[:contents]
        raise Error::Configuration, "no contents" unless Array === results
        
        # Map column name to column index.
        i = -1
        c = { }
        contents_columns.each do | n |
          c[n.to_sym] = i += 1
        end
        
        # require 'pp'; pp c;
        row_to_hash = c.map do | (k, i) |
          # $stderr.puts "k=#{k.inspect}, i=#{i.inspect}"
          "  h[#{k.inspect}] = #{Content::SYMBOL_ATTRIBUTES.include?(k) ? 'to_sym' : ''}(row[#{i}]);\n"   
        end * ''
        row_to_hash = "Proc.new do | row |\nh = { }\n#{row_to_hash}\nh\nend"
        # $stderr.puts "row_to_hash:\n#{row_to_hash}"
        row_to_hash = eval(row_to_hash)
        
        # Verify minimal columns.
        Selector::AXIES + [ :content_type, :content_key, :data ].each do | n |
          raise Error::Configuration, "no contents_columns for column #{n.inspect}" unless c[n]
        end

        row_i = 0
        bytes = 0
        begin
          row = nil
          results.each do | row |
            # $stderr.puts "row = #{row.inspect}"
            row_hash = row_to_hash.call(row)
            # $stderr.puts "row_hash = #{row_hash.inspect}"
            row_hash[:selector] = Selector.coerce(row_hash)

            # Handle encoding.
            decode_hash! row_hash

            data = row_hash[:data].freeze

            rows << row_hash
            
            # $stderr.write '.'
            row_i += 1
            bytes += data.size
          end
        rescue Exception => err
          raise err.class, "#{err} in #{identifier}: row #{row_i}:\n  #{row.inspect}\n  #{err.backtrace * "\n  "}"
        end
        
        time = Time.now.to_f - time_0; 
        log(:debug) { "Parsing #{identifier} DONE: #{row_i} rows, #{bytes} bytes, #{time} secs" }
        # File.open("/proc/self/statm", "r") { | fh | $stderr.puts fh.read }
        
        rows
      end


      # Parses YAML string into Array h.
      # structured as:
      #
      #  [ Content ]]
      def parse_yml_array content, identifier, rows = nil
        case content
        when Array
        when String
          content = parse_yml_raw(content, identifier)
        else
          raise ArgumentError, "parse_yml_array: #{identifier}: Expected String or Array, given #{content.class.name}"
        end

        content.map! do | h | 
          Content.new(h)
        end

        content
      end

      # Parses YAML string into Hash h.
      # structured as:
      #
      #  h[content_type][selector][content_key] = Content
      def parse_yml_hash content, identifier, h = nil
        case content
        when Array
        when String
          content = parse_yml_array(content, identifier)
        else
          raise ArgumentError, "parse_yml_hash: #{identifier}: Expected String or Array, given #{content.class.name}"
        end

        h ||= { }

        content.each do | c | 
          v = (h[c.content_type.to_sym] ||= { }) 
          v = (v[c.selector.to_sym] ||= { })
          v[c.content_key.to_sym] = c
        end

        h
      end


      # Convert String to Symbol.
      # Convert :_ to nil for compatiblity with Selector.
      def to_sym x
        x &&= x.to_sym
        x = nil if x == :_
        x
      end

      UNDERSCORE = '_'.freeze

      def decode_hash! hash
        case enc = hash.delete(:data_encoding)
        when :raw, nil, :_, UNDERSCORE, EMPTY_STRING, false
          false
        when :base64
          hash[:data] = Base64.decode64(hash[:data])
          true
        else
          raise Error::Configuration, "Invalid encoding #{enc.inspect}"
        end
      end

      extend self
    end
  end
end
