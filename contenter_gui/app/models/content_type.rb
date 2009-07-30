
#
# Represents a unique content type.
#
class ContentType < ActiveRecord::Base
  include ContentModel

  validates_format_of :code, :with => /\A([a-z_][a-z0-9_]*)\Z/
  validates_uniqueness_of :code


  validates_format_of :plugin, :with => /\A|[a-z_][a-z0-9_]*(::[a-z_][a-z0-9_]*)*\Z/i

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

  before_save :initialize_defaults!
  def initialize_defaults!
    self.key_regexp ||= /\A([^\s]+)\Z/.inspect
  end

  # The plugin class (if any) used to serialize and deserialize composite-valued
  # datatypes into the data field of Content
  def plugin_instance
    @plugin_instance ||= 
      eval(plugin.empty? ? 'Contenter::Plugin::Null' : plugin).new
  end

end

