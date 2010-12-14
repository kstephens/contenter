require 'digest/md5'
require 'attr_lazy'

# Shared behavior for Content and Content::Version.
module ContentBehavior
  # Early includes allow overrides by InstanceMethods in self.included.
  def self.append_features target
    # $stderr.puts "ContentBehavior.append_features #{target.name}"
    target.class_eval do
      include ContentModel
      include ContentAdditions
      include UuidModel
      include AuxDataModel
      include TasksModel
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

      (BELONGS_TO + [ :content_status ]).each do | x |
        belongs_to x, :extend => ModelCache::BelongsTo
        validates_presence_of x
      end

      # validates_presence_of :filename
       
      validates_presence_of :md5sum
      validates_format_of :md5sum, :with => Contenter::Regexp.md5sum

      before_validation :normalize_content_key!
      before_validation :plugin # force plugin mixin once content_key (and content_type) is known.
      before_validation :default_selectors!
      before_validation :initialize_md5sum!
      before_validation :update_content_status! if Content == target
      validate :verify_mime_type_against_content_type! if Content == target

      after_save :clear_data_changed!

      attr_lazy :data
    end

  end

  # Constants to be mixed into Content and Content::Version
  module Constants
    EMPTY_HASH = { }.freeze
    EMPTY_ARRAY = [ ].freeze
    EMPTY_STRING = ''.freeze
    UNDERSCORE = '_'.freeze

    # FIXME: Rename this to AXIES?
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
      BELONGS_TO.map { | x | :"#{x}_id" }.freeze

    FIND_COLUMNS =
      ([ :id, :uuid, :version, :content_status, :content_type, :filename, :md5sum, :data ] + BELONGS_TO).uniq.freeze
    
    QUERY_COLUMNS =
      (FIND_COLUMNS + BELONGS_TO_ID + [ :content_key_uuid, :content_type_id, :content_status_id, :tasks, :updater, :creator ]).uniq.freeze

    EQUAL_COLUMNS =
      ([ :uuid, :data ] + BELONGS_TO).freeze # :md5sum?
    
    # Used against AR::B#changed.
    CHANGE_COLUMNS = (BELONGS_TO_ID + [ :tasks, :filename, :data ]).map{|x| x.to_s.freeze}.freeze

    DISPLAY_COLUMNS =
      # Moves :md5sum and :data to end of Array.
     (FIND_COLUMNS + [ :updater, :creator ] - [ :tasks, :filename, :md5sum, :data ] + [ :tasks, :filename, :md5sum, :data ]).freeze

    SORT_COLUMNS = ([ :content_type ] + BELONGS_TO + [ :content_status ]).uniq.freeze

    LIST_COLUMNS = SORT_COLUMNS.freeze

    COPY_COLUMNS = (BELONGS_TO_ID + [ :data ]).freeze

    COLUMN_TO_CLASS = { }
    COLUMN_TO_CLASS.clear
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
      # opts[:model_class] = self # ???
      Content::Query.new(opts).find(opt)
    end
    
    def normalize_hash hash
      # $stderr.puts "  #{self} normalize_hash #{hash.inspect}"
      result = hash.dup
      
      BELONGS_TO.each do | column |
        # $stderr.puts "  #{self} normalize #{column.inspect}"
        cls = (COLUMN_TO_CLASS[column] ||= Object.const_get(column.to_s.classify))
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
        hash[column] ||= UNDERSCORE
      end
    end
    
  end # module

  module InstanceMethods
    # The uuid to copy from.
    attr_accessor :copy_from_uuid

    # Force the plugin to be mixed into this instance after #create and .find.
    def after_initialize 
      plugin if content_type
      self
    end

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


    ##################################################################
    # ContentType#mime_type validation support
    #

    def verify_mime_type_against_content_type!
      if ! (mime_type.code == '_' || mime_type.is_a_mime_type?(content_key.content_type.mime_type))
        errors.add(:mime_type, "must match mime-type: #{content_key.content_type.mime_type.to_s.inspect}")
        false
      else
        true
      end
    end

    def valid_mime_type_list
      (content_type ? content_type.valid_mime_type_list : MimeType.find(:all)).
        select { | mt | mt.code !~ /\/\*\Z/} 
    end


  [ Language, Country, Brand, Application ].each do | cls |
    name = cls.name.underscore
    class_eval <<"END", __FILE__, __LINE__
  def valid_#{name}_list
    content_type ? content_type.valid_#{name}_list : #{cls.name}.all
  end
END
  end

    ##################################################################


    # Returns an Array suitable for use in sorting Content objects.
    def sort_array
      @sort_array ||= 
        (
         SORT_COLUMNS.map { | k | send(k).code } +
         [ - self.version ]
         ).freeze
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
      result = { 
        :id => id, 
        :uuid => uuid, 
        :md5sum => md5sum, 
        :data => data, 
        :data_encoding => data_encoding,
        :version => version, 
        :content_status => (content_status && content_status.code), 
        :updater => (updater && updater.login),
        :creator => (creator && creator.login),
      }
      
      BELONGS_TO.each do | x |
        v = send(x)
        if v
          v.add_to_hash(result)
        else
          result[x] = UNDERSCORE
        end
      end
      result
    end


    def data_encoding
      is_binary? ? :base64 : :raw
    end


    def to_s
      data
    end


    def to_contenter_yml
      data
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
        cls = (COLUMN_TO_CLASS[column] ||= Object.const_get(column.to_s.classify))
        obj = cls[hash]
        self.send("#{column}=", obj) if obj
      end

      # Meh.
      self.filename ||= ''
    end
    
    def initialize_md5sum!
      self[:md5sum] ||= 
        Digest::MD5.new.hexdigest(self.data || EMPTY_STRING).downcase
    end
    
    def md5sum
      initialize_md5sum!
    end
    
   # Support for notifying plugin ContentMixins.
    def data= x
      return unless x
      if self[:data] != x
        @data_changed = true
        self[:md5sum_old] ||= self[:md5sum]
        self[:md5sum] = nil
        data_changed! if respond_to?(:data_changed!)
      end
      self[:data] = x
    end

    def content_attributes_changed
      changed & CHANGE_COLUMNS
    end

    def content_changed?
      result = ! content_attributes_changed.empty?
      @content_changed ||= result
      result
    end

    def clear_data_changed!
      @data_changed = nil
    end

    # Returns the Plugin instance for this object ContentType.
    # Extends self with the Plugin's ContentMixin.
    def plugin
      # $stderr.puts "#{self.class.name} #{id || 'new'} plugin"
      @plugin ||=
        (content_type ? 
         content_type.plugin_instance :
         ContentType.null_plugin_instance
         ).mix_into_object(self)
    end


    # NOTE: if you use update_attribute(), you are going direct to the database
    # and rails will not call your callbacks and/or update the #changed attribute list.
    # 
    # So don't be surprised if content_status is not set to :modified when
    # you use update_attribute().
    #
    def update_content_status!
      @content_status_old = content_status

      case 
        # See set_content_status! below.
      when @update_content_status_disabled
        # NOTHING

        # Probably a Content::Version object, we don't modify them here.
      when Content::Version === self
        # NOTHING
        
        # New records start as :created.
      when new_record?
        self.content_status = ContentStatus[:created]

        # Old records get :initial.
      when ! self.content_status
        self.content_status = ContentStatus[:initial]

        # If data or other columns have changed, 
        # mark it as :modified.
      when content_changed?
        self.content_status = ContentStatus[:modified]

      end
      # $stderr.puts "  #{self.class} #{id.inspect} update_content_status! #{@content_status_old.to_s.inspect} => #{content_status.to_s.inspect}"
      self
    end
    
    def set_content_status! status
      status = ContentStatus[status]
      if self.content_status != status
        self.class.transaction do
          begin
            update_content_status_disabled_save = @update_content_status_disabled
            @update_content_status_disabled = true

            notify_observers! :before_set_content_status!

            # Update self now.
            self.content_status = status
            save!

            # Update the latest version also.

            # since we took Content#status out of versioning's pervue, we must pass the change along 
            # if we want the content record and its latest version to always have the same status.
            # We disable optimistic locking because it prevents a staleobject error due to NULL in 
            # lock_version column
            without_locking do
              vl = self.versions.latest
              vl.content_status = status
              vl.save!
            end
            
            notify_observers! :after_set_content_status!
          ensure
            @update_content_status_disabled = update_content_status_disabled_save
          end
        end
      end
    end

    # Returns a ContentConverter::Content object.
    def conversion dst = nil
      if ! dst || dst.empty?
        self
      else
        ContentConversion.convert(self, dst)
      end
    end

    # Returns a ContentConverter::Content object.
    def content
      @content ||= 
        Contenter::ContentConverter::Content.new(:data => self.data, :md5sum => self.md5sum, :mime_type => self.mime_type.to_s)
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


