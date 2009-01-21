require 'contenter/uuid'

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


    def value_name_uuid
      @value_name_uuid ||= (name.underscore + "_uuid").to_sym
    end


    def values_from_hash hash, mode = :find
      values = 
      case 
      when x = hash[value_name_uuid]
        { :uuid => x }
      when x = hash[value_name_id]
        { :id => x }
      else
        { :code => (hash[value_name] || '_').to_s }
      end
      values
    end


    def find_by_hash arg, hash
      obj = find(arg, :conditions => values_from_hash(hash))
      # $stderr.puts "  #{self}.find_by_hash(#{arg.inspect}, #{hash.inspect}) =>\n    #{obj.inspect}"
      obj
    end


    # Locate an object by Hash, code (Symbol), uuid (String), or id (Integer).
    def [](x)
      case x
      when Hash
        find_by_hash(:first, x)
      when nil, Symbol
        find(:first, :conditions => [ 'code = ?', (x || '_').to_s ])
     when String
        find(:first, :conditions => [ 'uuid = ? OR code = ?', (x || '').to_s, (x || '_').to_s ])
      when Integer
        find(:first, :conditions => [ 'id = ?', x ])
      end
    end


    # Finds or creates an object.
    def create_from_hash hash
      values = values_from_hash hash
      unless obj = find(:first, :conditions => values)
        return nil if values[:id]
        obj = create!(values)
        raise ArgumentError, "#{obj.errors.to_s}" unless obj.errors.empty?
      end
      obj
    end
  end


  # Adds its attributes to a flattened hash.
  def add_to_hash hash = { }
    hash[self.class.value_name] = code
    if respond_to?(:uuid) 
      hash[self.class.value_name_uuid] = initialize_uuid!
    end
    hash
  end

end

