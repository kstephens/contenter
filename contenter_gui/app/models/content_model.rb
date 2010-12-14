require 'cabar/observer/active_record'

# Common functionality for all content model objects that have
# #code, #uuid fields.
module ContentModel
  def self.included target
    super
    target.extend ClassMethods
    target.class_eval do
      include Cabar::Observer::ActiveRecord
      include UserTracking
      include UrlModel
      ModelCache.register_model target
    end
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
        case hash[value_name]
        when ActiveRecord::Base
          { :id => (hash[value_name.id]) }
        else
          { :code => (hash[value_name] || '_').to_s }
        end
      end
      # $stderr.puts "  ContentModel#values_from_hash #{self} #{hash.inspect} => #{values.inspect}"
      values
    end


    def find_by_hash arg, hash
      conditions = values_from_hash hash
      obj = ModelCache.cache_for self, :find_by_hash, [ arg, conditions ] do  
        find(arg, :conditions => conditions)
      end
      # $stderr.puts "  ContentModel#find_by_hash #{self} #{hash.inspect} => #{obj.inspect}"
=begin
      $stderr.puts "  #{self}.find_by_hash(#{arg.inspect}, #{hash.inspect})\n  cond = #{conditions.inspect} =>\n    #{obj.inspect}"
      $stderr.puts "  #{obj.class.name}.ancestors => #{obj.class.ancestors * "\n"}"
      $stderr.puts "  #{obj.class.name}#updated? => #{obj.respond_to?(:updated?).inspect}"
=end
      obj
    end


    UNDERSCORE = '_'.inspect

    # Locate an object by Hash, code (Symbol), uuid (String), or id (Integer).
    def [](x)
      case x
      when self
        return x
      when Hash
        return find_by_hash(:first, x)
      when nil, Symbol
        ModelCache.cache_for self, :[], x do
          find(:first, :conditions => [ 'code = ?', (x || UNDERSCORE).to_s ])
        end
      when String
        ModelCache.cache_for self, :[], x.dup do
          if x.size == 36 && respond_to?(:uuid)
            conditions = [ 'uuid = ? OR code = ?', x, x ]
          else
            conditions = [ 'code = ?', x ]
          end
          find(:first, :conditions => conditions)
        end
      when Integer
        ModelCache.cache_for self, :[], x do
          find(:first, :conditions => [ 'id = ?', x ])
        end
      else
        raise TypeError, "in #{self.name}[], given #{x.class.name}"
      end
    end


    # Finds or creates an object.
    def create_from_hash hash
      values = values_from_hash hash
      # $stderr.puts "  ContentModel#create_from_hash #{self} #{hash.inspect} => #{values.inspect}"
      ModelCache.cache_for self, :create_from_hash, values do
        self.transaction do
          unless obj = find(:first, :conditions => values)
            return nil if values[:id]
            obj = create!(values)
            raise ArgumentError, "#{self} #{obj.errors.to_s}" unless obj.errors.empty?
          end
          obj
        end
      end
    end
  end


  # Adds its attributes to a flattened Hash.
  def add_to_hash hash = { }
    hash[self.class.value_name] = code
    if respond_to?(:uuid) 
      hash[self.class.value_name_uuid] = initialize_uuid!
    end
    hash
  end


  def to_s
    code
  end

end

