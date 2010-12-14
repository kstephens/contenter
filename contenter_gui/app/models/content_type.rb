
#
# Represents a unique content type.
#
class ContentType < ActiveRecord::Base
  include ContentModel
  include AuxDataModel

  belongs_to :mime_type
  validates_presence_of :mime_type_id

  validates_format_of :code, :with => /\A([a-z_][a-z0-9_]*)\Z/
  validates_uniqueness_of :code

  validates_format_of :plugin, :with => /\A(|[a-z_][a-z0-9_]*(::[a-z_][a-z0-9_]*)*)\Z/i
  validates_presence_of :plugin_instance

  has_many :content_keys do 
    def by_code(code)
      result = find(:all, :conditions => [ 'content_keys.code = ?', code.to_s ], :limit => 2)
      result = result.size == 1 ? result.first : nil
      result
    end
  end

  has_many :contents, :through => :content_keys

  # Returns a Regexp object for the key_regexp String.
  def key_regexp_rx
    @key_regexp_rx ||=
      key_regexp &&  
      begin
        rx = eval(key_regexp)
        raise ArgumentError unless Regexp === rx
        rx
      end
  end

  def valid_mime_type_list
    @valid_mime_type_list ||=
      (x = self.aux_data[:valid_mime_type_list]) ? x.map{|c| MimeType[c]} :
      (MimeType.all_of_mime_type(mime_type) + [ MimeType[:_] ]).uniq.freeze
  end

  [ Language, Country, Brand, Application ].each do | cls |
    name = cls.name.underscore
    class_eval <<"END", __FILE__, __LINE__
  def valid_#{name}_list
    @valid_#{name}_list||=
        (self.aux_data[:valid_#{name}_list] || #{cls.name}.all).map{|c| #{cls.name}[c]}
  end
END
  end

  before_save :initialize_defaults!
  def initialize_defaults!
    self.key_regexp ||= /\A([^\s]+)\Z/.inspect
    self.mime_type ||= MimeType[:'*/*']
    self.plugin ||= ''
  end

  # The plugin class (if any) used to serialize and deserialize composite-valued
  # datatypes into the data field of Content
  def plugin_instance
    @plugin_instance ||= 
      Contenter::Plugin.factory(plugin).new(:content_type => self)
  end

  # The plugin instance used where Content#content_type == nil.
  def self.null_plugin_instance
    @@null_plugin_instance ||=
      Contenter::Plugin::Null.new({ })
  end

end

