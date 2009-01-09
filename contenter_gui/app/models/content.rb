#
# Reprensts the content for a particular:
#
#   content_key
#   language
#   country
#   brand
#   application
#
class Content < ActiveRecord::Base
  include ContentModel

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
    ([ :id, :uuid, :content_type, :content ] + BELONGS_TO).freeze

=begin
  validates_uniqueness_of :content_key, 
    :scope => BELONGS_TO_ID
=end

  def content_type
    @content_type ||= content_key.content_type
  end

  def key
    content_key.code
  end

  def key= x
    @key = x
  end


  def self.find_column_names
    FIND_COLUMNS
  end


  def self.find_by_params opt, params
    sql = <<"END"
SELECT #{table_name}.* 
FROM #{table_name}, #{BELONGS_TO.map{|x| x.to_s.pluralize} * ', '}, content_types
WHERE
    #{BELONGS_TO.map{|x| "(#{x.to_s.pluralize}.id = contents.#{x}_id)"} * "\nAND "}
AND (content_types.id = content_keys.content_type_id)
END

    # Construct find :conditions.
    find_column_names.each do | column |
      if params.key?(column)
        field = 
          case column 
          when :id 
            'contents.id'
          when :uuid
            'contents.uuid'
          when :content_key_uuid
            'content_keys.uuid'
          when :content
            'contents.content'
          else 
            "#{column.to_s.pluralize}.code"
          end
        value = params[column]

        # Coerce value.
        case value
        when Symbol
          value = value.to_s
        when Regexp
          value = value.inspect
        when String
          value = value.dup
        end

        # Handle meta values.
        case
          # Match NULL
        when value == 'NULL'
          field += ' IS NULL'

          # Match !NULL
        when value == '!NULL'
          field += ' IS NOT NULL'

          # Match Regexp
        when value =~ /\A\/.*\/Z/
          value = value.sub(/^\//, '').sub(/\/$/, '')
          field += ' ~ %s'

          # Match not Regexp
        when value =~ /\A!\/.*\/\Z/
          value = value.sub(/^!\//, '').sub(/\/$/, '')
          field += ' !~ %s'

          # Match not String.
        when value.sub!(/\A!/, '')
          field = "#{field} IS NULL OR #{field} <> %s"

          # Match exact.
        else
          field += ' = %s'
        end

        sql << "\nAND (#{field % Content.connection.quote(value)})"
      end
    end

    case opt
    when :first
      sql << "\nLIMIT 1"
    end

    # $stderr.puts "  sql =\n #{sql}"

    result = 
      Content.
      find_by_sql(sql)

    case opt
    when :first
      result = result.first
    end

    result
  end


  def to_hash
    result = { :id => id, :uuid => uuid, :content => content }
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


  def self.load_from_hash hash
    hash = hash.dup

    if v = hash[:key]
      hash[:content_key] = v
      hash.delete(:key)
    end

    params = hash.dup
    params.delete(:content)
    if obj = find_by_params(:first, params)
      hash = normalize_hash(hash)
      $stderr.puts "  UPDATE: load_from_hash(#{hash.inspect})"
      obj.attributes = hash
      obj.save!
    else
      hash = normalize_hash(hash)
      $stderr.puts "  CREATE: load_from_hash(#{hash.inspect})"
      obj = self.create(hash)
    end
    obj
  end


  def self.load_from_yaml! yaml
    result = YAML::load(yaml)
    columns = result[:result_columns]
    result[:results].map do | r |
      i = -1
      hash = columns.inject({ }) do | h, k |
        h[k] = r[i += 1]
        h
      end
      hash.delete(:id)
      load_from_hash hash
    end
  end


  def self.normalize_hash hash
    result = hash.dup

    BELONGS_TO.each do | column |
      $stderr.puts "normalize #{column.inspect}"
      cls = Object.const_get(column.to_s.classify)
      obj = cls.create_from_hash(hash)
      result[column] = obj
    end
    # content_type is handled via content_key.
    result.delete(:content_type)

    result
  end


  before_save :default_selectors!

  EMPTY_HASH = { }.freeze

  def default_selectors!
    hash = to_hash
    BELONGS_TO.each do | column |
      next if self.send(column)
      cls = Object.const_get(column.to_s.classify)
      obj = cls[hash]
      self.send("#{column}=", obj) if obj
    end
  end

  before_save :initialize_uuid!
  def initialize_uuid!
    self.uuid ||= Contenter::UUID.generate_random
  end

end

