
# Common functionality for all content model objects.
module ContentModel
  def self.included base
    super
    base.extend ClassMethods
  end

  module ClassMethods
    def value_name
      @value_name ||= name.underscore.to_sym
    end

    def value_name_id
      @value_name_id ||= (name.underscore + "_id").to_sym
    end

    def values_from_hash hash, mode = :find
      values = 
      case 
      when x = hash[value_name_id]
        { :id => x }
      else
        { :code => (hash[value_name] || '_').to_s }
      end
      values
    end

    def find_by_hash arg, hash
      obj = find(arg, :conditions => values_from_hash(hash))
      $stderr.puts "  #{self}.find_by_hash(#{arg.inspect}, #{hash.inspect}) =>\n    #{obj.inspect}"
      obj
    end

    def [](x)
      case x
      when Hash
        find_by_hash(:first, x)
      when nil, Symbol, String
        find(:first, :conditions => [ 'code = ?', (x || '_').to_s ])
      when Integer
        find(:first, :conditions => [ 'id = ?', x ])
      end
    end

    # Finds an object 
    def create_from_hash hash
      values = values_from_hash hash
      unless obj = find(:first, :conditions => values)
        return nil if values[:id]
        obj = create(values)
      end
      obj
    end
  end

  def add_to_hash hash = { }
    hash[self.class.value_name] = code
    hash
  end

end

