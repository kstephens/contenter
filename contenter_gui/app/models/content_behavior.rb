require 'contenter/uuid'
require 'digest/md5'

# Shared behavior for Content and Content::Version.
module ContentBehavior
  # Early includes allow overrides by InstanceMethods in self.included.
  def self.append_features target
    # $stderr.puts "ContentBehavior.append_features #{target.name}"
    target.class_eval do
      include ContentModel
      include ContentAdditions
    end
  end

  def self.included target
    # $stderr.puts "ContentBehavior.included #{target.name}"
    super

    Constants.constants.each do | c |
      v = Constants.const_get(c)
      # $stderr.puts "#{target}::#{c} => #{v.inspect}"
      target.const_set(c, v)
    end

    target.extend(ClassMethods)

    target.class_eval do
      include InstanceMethods

      BELONGS_TO.each do | x |
        belongs_to x
        validates_presence_of x
      end

      validates_length_of :uuid, :is => 36
      validates_presence_of :uuid
      validates_format_of :uuid, :with => /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\Z/i # e.g. 9301c481-bc3c-4edc-8ce0-8dd66c097473
       
      validates_length_of :md5sum, :is => 32
      validates_presence_of :md5sum
      validates_format_of :md5sum, :with => /\A[0-9a-f]{32}\Z/

      before_validation :normalize_content_key!
      before_validation :default_selectors!
      before_validation :initialize_uuid!
      before_validation :initialize_md5sum!

      # Force the plugin to be mixed into this instance after loading.
      after_find :plugin
    end

  end

  # Constants to be mixed into Content and Content::Version
  module Constants
    EMPTY_HASH = { }.freeze unless defined? EMPTY_HASH
    EMPTY_ARRAY = [ ].freeze unless defined? EMPTY_ARRAY

    BELONGS_TO =
      [
       :content_key,
       :language,
       :country,
       :brand,
       :application,
       :mime_type,
      ].freeze

    BELONGS_TO_ID =
      BELONGS_TO.map { | x | "#{x}_id".to_sym }.freeze
    
    FIND_COLUMNS =
      ([ :id, :uuid, :version, :content_type, :md5sum, :data ] + BELONGS_TO).uniq.freeze
    
    QUERY_COLUMNS =
      (FIND_COLUMNS + BELONGS_TO_ID + [ :content_type_id ]).uniq.freeze

    EQUAL_COLUMNS =
      ([ :uuid, :data ] + BELONGS_TO).freeze # :md5sum?
    
    DISPLAY_COLUMNS =
      # Moves :md5sum and :data to end of Array.
     (FIND_COLUMNS - [ :md5sum, :data ] + [ :md5sum, :data ]).freeze

    SORT_COLUMNS = ([ :content_type ] + BELONGS_TO).freeze

    LIST_COLUMNS = SORT_COLUMNS.freeze

    COPY_COLUMNS = (BELONGS_TO_ID + [ :data ]).freeze
  end


  # Class methods mixed into Content and Content::Version.
  module ClassMethods
    ####################################################################
    # Query support.
    #

    def find_column_names
      FIND_COLUMNS
    end
    
    def query_column_names
      QUERY_COLUMNS
    end
    
    def display_column_names
      DISPLAY_COLUMNS
    end

    def order_by
      @@order_by ||=
        BELONGS_TO.
        map { | x |
        x = x.to_s
        xs = x.pluralize # x.classify.table_name.
        "(SELECT #{xs}.code FROM #{xs} WHERE #{xs}.id = #{x}_id)"
      }.join(', ')
    end


    # Deprecated: Use Content::Query.new(:params => ...).find(...)
    def find_by_params opt, params, opts = { }
      opts[:params] = params
      Content::Query.new(opts).find(opt)
    end
    
    def normalize_hash hash
      # $stderr.puts "  #{self} normalize_hash #{hash.inspect}"
      result = hash.dup
      
      BELONGS_TO.each do | column |
        # $stderr.puts "  #{self} normalize #{column.inspect}"
        cls = Object.const_get(column.to_s.classify)
        obj = cls.create_from_hash(hash)
        result[column] = obj
        # $stderr.puts "  #{self} normalize #{column.inspect} => #{obj.inspect}"
      end
      # content_type is handled via content_key.
      result.delete(:content_type)
      
      result
    end
    

    # Default columns to '_' wildcards.
    def default_hash! hash
      BELONGS_TO.each do | column |
        hash[column] ||= '_'
      end
    end
    
  end # module

  module InstanceMethods
    def content_type
      @content_type ||
        ((x = content_key) &&
         x.content_type
         )
    end
    
    def content_type_id
      (x = content_type) &&
        x.id
    end
    
    def content_type_id= x
      @plugin = nil
      @content_type = ContentType[x.to_i]
    end
    
    def content_type_code
      (x = content_type) &&
        x.code
    end
    
    def content_type_code= x
      @plugin = nil
      @content_type = ContentType[x.to_s]
    end
    
    def content_key_code
      (x = content_key) &&
        x.code
    end
    
    def content_key_code= x
      @content_key_code = x
    end

    # Returns an Array suitable for use in sorting Content objects.
    def sort_array
      @sort_array ||= SORT_COLUMNS.map { | k | send(k).code }.freeze
    end
    

    def normalize_content_key!
      if @content_type && @content_key_code
        # $stderr.puts "  normalize_content_key! #{self.inspect}"
        self.content_key = 
          ContentKey.create_from_hash(:content_key => @content_key_code, 
                                      :content_type_id => @content_type.id) ||
          (raise Error, "Cannot create content_key for #{@content_type.inspect} #{@content_key_code.inspect}")
        @content_type = @content_key_code = nil
        @plugin = nil
        # $stderr.puts "normalized to content_key #{@content_key.inspect}"
      end
    end
    
    # Returns true if all elements in Hash match this object.
    def is_equal_to_hash? hash
      EQUAL_COLUMNS.all? do | k | 
        ! hash.key?(k) || (self.send(k) == hash[k])
      end
    end
    
    
    # Returns Array of all elements that differ between a Hash and this object.
    def diff_to_hash hash
      EQUAL_COLUMNS.reject do | k | 
        ! hash.key?(k) || (self.send(k) == hash[k])
      end.map do | k |
        [ k, self.send(k), hash[k] ]
      end
    end


    # Convert this Content (and its identifiers: ContentKey, Country, Language, etc.) to a Hash.
    def to_hash
      result = { :id => id, :uuid => uuid, :md5sum => md5sum, :data => data }
      result[:version] = version
      
      BELONGS_TO.each do | x |
        v = send(x)
        if v
          v.add_to_hash(result)
        else
          result[x] = '_'
        end
      end
      result
    end


    # the user-editable values in a Hash
    def content_values 
      hash = { }
      COPY_COLUMNS.each do | field |
        hash[field] = self.send(field)
      end
      hash
    end
    
    def copy_from! other
      COPY_COLUMNS.each do | field |
        send("#{field}=", Hash === other ? hash[field] : other.send(field))
      end
      self
    end


    def default_selectors!
      hash = to_hash
      BELONGS_TO.each do | column |
        next if self.send(column)
        cls = Object.const_get(column.to_s.classify)
        obj = cls[hash]
        self.send("#{column}=", obj) if obj
      end
    end
    
    def initialize_uuid!
      self.uuid = Contenter::UUID.generate_random if self.uuid.blank?
    end
    
    def initialize_md5sum!
      self.md5sum = Digest::MD5.new.hexdigest(self.data)
    end
    
    # Support for notifying plugin ContentMixins.
    def data= x
      if self[:data] != x
        data_changed! if respond_to?(:data_changed!)
      end
      self[:data] = x
    end

    # Returns the Plugin instance for this object ContentType.
    # Extends self with the Plugin's ContentMixin.
    def plugin
      @plugin ||=
        (content_type ? 
         content_type.plugin_instance :
         ContentType.null_plugin_instance
         ).mix_into_object(self)
    end
    
  end # module

  Constants.constants.each do | c |
    v = Constants.const_get(c)
    # $stderr.puts "#{self}::#{c} => #{v.inspect}"
    self.const_set(c, v)
  end

end # module


module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter
      # The stock version of this only unescapes_bytea values if
      # the raw data contains /\\\d{3}/, which clobbers the
      # common escape of '\\'.
      # See https://rails.lighthouseapp.com/projects/8994-ruby-on-rails/tickets/1837-postgressqladapterunescape_bytea-does-not-handle
      def unescape_bytea(value)
        PGconn.unescape_bytea(value)
      end
    end
  end
end


