require 'digest/md5'

#
# Represents the content for a particular:
#
#   content_key
#   language
#   country
#   brand
#   application
#   mime_type
#
# Actual content is stored in Content#data.
#
class Content < ActiveRecord::Base
  EMPTY_HASH = { }.freeze unless defined? EMPTY_HASH

  # Base Content::Error class.
  class Error < ::Exception
    # Raised when an edit is attempted on a version that is older.
    class Conflict < self; end
    # Raised when an edit is attempted on a based on an ambiguous lookup.
    class Ambiguous < self; end
  end

  ###############################################

  include ContentModel
  include ContentAdditions


  # USE_VERSION = (RAILS_ENV != 'test') unless defined? USE_VERSION
  USE_VERSION = true unless defined? USE_VERSION
  if USE_VERSION 
    acts_as_versioned # generates Content::Version.
    set_locking_column :version
  end

  ###############################################

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

  BELONGS_TO.each do | x |
    belongs_to x
    validates_presence_of x
  end
  
  FIND_COLUMNS =
    ([ :id, :uuid, :version, :content_type, :md5sum, :data ] + BELONGS_TO).freeze

  EQUAL_COLUMNS =
    ([ :uuid, :data ] + BELONGS_TO).freeze # :md5sum?

  DISPLAY_COLUMNS =
     (FIND_COLUMNS - [ :md5sum, :data ] + [ :md5sum, :data ]).freeze

  validates_length_of :uuid, :is => 36
  validates_presence_of :uuid
  validates_format_of :uuid, :with => /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\Z/i # e.g. 9301c481-bc3c-4edc-8ce0-8dd66c097473
  validates_uniqueness_of :uuid

  validates_length_of :md5sum, :is => 32
  validates_presence_of :md5sum
  validates_format_of :md5sum, :with => /\A[0-9a-f]{32}\Z/

=begin
  validates_uniqueness_of :content_key, 
    :scope => BELONGS_TO_ID
=end

  SORT_COLUMNS = [ :content_type ] + BELONGS_TO

  def sort_array
    @sort_array ||= SORT_COLUMNS.map { | k | send(k).code }
  end


  before_validation :normalize_content_key!
  def normalize_content_key!
    if @content_type && @content_key_code
      # $stderr.puts "  normalize_content_key! #{self.inspect}"
      self.content_key = ContentKey.create_from_hash(:content_key => @content_key_code, :content_type_id => @content_type.id)
      @content_type = @content_key_code = nil
      $stderr.puts "normalized to content_key #{@content_key.inspect}"
    end
  end

  # Force the plugin to be mixed into this instance after loading.
  after_find :plugin


  ####################################################################
  # Query support.
  #


  def self.find_column_names
    FIND_COLUMNS
  end

  def self.display_column_names
    DISPLAY_COLUMNS
  end

  def self.order_by
    @@order_by ||=
      BELONGS_TO.
      map { | x |
      x = x.to_s
      xs = x.pluralize
      "(SELECT #{xs}.code FROM #{xs} WHERE #{xs}.id = #{x}_id)"
    }.join(', ')
  end


  def self.find_by_params opt, params, opts = { }
    opts[:params] = params
    Content::Query.new(opts).find(opt)
  end


  # Returns true if all elements in Hash match this object.
  def is_equal_to_hash? hash
    EQUAL_COLUMNS.all? do | k | 
      ! hash.key?(k) || (self.send(k) == hash[k])
    end
  end


  # Returns Array of all elements between Hash and this object.
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
    if USE_VERSION 
      result[:version] = version
    end

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


  def self.normalize_hash hash
    result = hash.dup

    BELONGS_TO.each do | column |
      # $stderr.puts "normalize #{column.inspect}"
      cls = Object.const_get(column.to_s.classify)
      obj = cls.create_from_hash(hash)
      result[column] = obj
    end
    # content_type is handled via content_key.
    result.delete(:content_type)

    result
  end


  # Default columns to '_' wildcards.
  def self.default_hash! hash
    BELONGS_TO.each do | column |
      hash[column] ||= '_'
    end
  end


  before_validation :default_selectors!
  def default_selectors!
    hash = to_hash
    BELONGS_TO.each do | column |
      next if self.send(column)
      cls = Object.const_get(column.to_s.classify)
      obj = cls[hash]
      self.send("#{column}=", obj) if obj
    end
  end

  before_validation :initialize_uuid!
  def initialize_uuid!
    self.uuid = Contenter::UUID.generate_random if self.uuid.blank?
  end

  before_validation :initialize_md5sum!
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
    if content_type
      @plugin ||=
        content_type.plugin_instance.mix_into_object(self)
    else
      @plugin ||= ContentType[:phrase].plugin_instance.mix_into_object(self)
    end
  end

end


Content::Version.class_eval do
  include VersionList::ChangeTracking
  include ContentAdditions
  include UserTracking

 
  has_many :version_list_content_version_views, 
           :foreign_key => :content_version_id

  has_many :version_lists,
           :through => :version_list_content_version_views


  Content::BELONGS_TO.each do | x |
    belongs_to x
  end


  def is_current_version?
    content.version == self.version
  end

  # Give Content a chance to respond before raising - allows Mixed in methods to work for versions
  def method_missing(name, *args)
    return content.send(name, *args) if content.respond_to?(name)
    super
  end

  # the user-editable values as of this content version. 
  def content_values 
    (Content::BELONGS_TO_ID + [ :data ]).inject({}) do |all, field|
      all[field] = attributes[field]
      all
    end
  end

end


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


require 'content_additions'
require 'content_version'

