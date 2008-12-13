
#
# Represents unique content key for a particular content_type.
#
class ContentKey < ActiveRecord::Base
  include ContentModel

  
  serialize :data

  BELONGS_TO =
    [
     :content_type,
    ].freeze
  BELONGS_TO_ID =
    BELONGS_TO.map { | x | "#{x}_id".to_sym }.freeze

  BELONGS_TO.each do | x |
    belongs_to x
  end
  BELONGS_TO.each do | x |
    validates_presence_of x
  end
  
  FIND_COLUMNS =
    ([ :id, :uuid, :code ] + BELONGS_TO).freeze

  validates_format_of :code, :with => /\A([a-z_][a-z0-9_]*)\Z/
  validates_uniqueness_of :code, :scope => BELONGS_TO_ID

  def before_save
    super
    self.name ||= ''
    self.description ||= ''
    self.data ||= { }
  end

  def self.find_by_hash arg, hash
    hash[:content_type_obj] = 
      content_type = 
      ContentType.find_by_hash(:first, hash)
    $stderr.puts "  content_type = #{content_type.inspect}"
    hash[:content_type_id] = content_type && content_type.id
    # $stderr.puts "  #{self}.find_by_hash(#{arg.inspect}, #{hash.inspect})"
    obj = find(arg, :conditions => [ 'code = ? AND content_type_id = ?', hash[:content_key], hash[:content_type_id] ])
    $stderr.puts "  #{self}.find_by_hash(#{arg.inspect}, #{hash.inspect}) =>\n    #{obj.inspect}"
    obj
  end


  def self.create_from_hash hash
    unless obj = find_by_hash(:first, hash)
      obj = create(:code => hash[:content_key], :content_type => hash[:content_type_obj])
    end
    obj
  end


  def self.load_from_hash hash
    hash = hash.dup # find_by_hash mutates hash
    unless obj = find_by_hash(:first, hash)
      obj = create(:code => hash[:content_key], :content_type_id => hash[:content_type_id])
    end
    obj
  end


  def add_to_hash hash = { }
    hash[:content_key] = code
    hash[:content_type] = content_type.code
    hash
  end


  before_save :initialize_uuid!
  def initialize_uuid!
    self.uuid ||= Contenter::UUID.generate_random
  end

end


