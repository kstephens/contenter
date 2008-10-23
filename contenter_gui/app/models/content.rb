class Content < ActiveRecord::Base
  BELONGS_TO =
    [
     :content_type,
     :language,
     :country,
     :brand,
     :application,
    ].freeze
  BELONGS_TO_ID =
    BELONGS_TO.map { | x | "#{x}_id".to_sym }.freeze

  BELONGS_TO.each do | x |
    belongs_to x
  end
  
  FIND_COLUMNS =
    ([ :id, :key ] + BELONGS_TO).freeze

  validates_format_of :key, :with => /\A([a-z_][a-z0-9_]*)\Z/i
  validates_uniqueness_of :key, 
    :scope => BELONGS_TO_ID

  def self.find_column_names
    FIND_COLUMNS
  end

  def self.find_by_params opt, params
    fields = [ ]
    values = [ ]

    # Construct find :conditions.
    find_column_names.each do | column |
      if params.key?(column)
        field = column == :id ? "id" : "#{column}_id"
        value = params[column]
        case
        when column == :key
          field = 'key = ?'
          values << params[column]
        when value == 'NULL'
          field += " IS NULL"
        when value == '!NULL'
          field += " IS NOT NULL"
        else
          if value.sub!(/^!/, '')
            field = "(#{field} IS NULL OR #{field} <> ?)"
          else
            field += " = ?"
          end
          unless column == :id
            if value.empty?
              value = '_'
            end
            cls = Object.const_get(column.to_s.classify)
            obj = cls.find(:first, :conditions => [ 'code = ?', value ])
            value = obj ? obj.id : 0
          end
          values << value
        end
        fields << field
      end
    end

    # Search for all results.
    where = fields.join(' AND ')
    conditions = [ where, *values ]

    result = 
      Content.
      find(opt, 
           :conditions => conditions
           )

    result
  end


  def self.load_from_yaml! yaml
    result = YAML::load(yaml)
    columns = result[:result_columns]
    result[:results].each do | r |
      i = -1
      hash = columns.inject({ }) do | h, k |
        h[k] = r[i += 1]
        h
      end
      hash.delete(:id)
      params = hash.dup
      params.delete(:content)
      if obj = find_by_params(:first, params)
        hash = normalize_hash(hash)
        obj.attributes = hash
        obj.save!
      else
        self.create(normalize_hash(hash))
      end
    end
  end


  def self.normalize_hash hash
    result = hash.dup
    BELONGS_TO.each do | column |
      value = hash[column] || '_'
      cls = Object.const_get(column.to_s.classify)
      obj = cls.find(:first, :conditions => [ 'code = ?', value.to_s ])
      result[column] = obj
    end

    result
  end


  before_save :default_selectors!

  def default_selectors!
    BELONGS_TO.each do | column |
      necolumnt if self.send(column)
      cls = Object.const_get(column.to_s.classify)
      obj = cls.find(:first, :conditions => [ 'code = ?', '_' ])
      self.send("#{column}=", obj) if obj
    end
  end
end
