#
# Shared behavior for ContentKey and ContentKey::Version.
#
module ContentKeyBehavior
  # Early includes allow overrides by InstanceMethods in self.included.
  def self.append_features target
    # $stderr.puts "ContentKeyBehavior.append_features #{target.name}"
    target.class_eval do
      include ContentModel
      include ContentKeyAdditions
      include UuidModel
      include AuxDataModel
    end
    super
  end

  def self.included target
    # $stderr.puts "ContentKeyBehavior.included #{target.name}"
    super

    Constants.constants.each do | c |
      v = Constants.const_get(c)
      # $stderr.puts "#{target}::#{c} => #{v.inspect}"
      target.const_set(c, v)
    end

    target.extend(ClassMethods)

    target.class_eval do
      include InstanceMethods
      ModelCache.register_model target
      
      BELONGS_TO.each do | x |
        belongs_to x
        validates_presence_of x
      end

      opts = { }
      opts[:dependent] = :destroy if target.name !~ /::Version\Z/
      has_many :contents, opts

      before_validation :initialize_defaults!

      validates_presence_of :code
    end
  end


  module Constants
    BELONGS_TO =
      [
       :content_type,
      ].freeze

    BELONGS_TO_ID =
    BELONGS_TO.map { | x | "#{x}_id".to_sym }.freeze
    
    FIND_COLUMNS =
      ([ :id, :uuid, :code ] + BELONGS_TO).freeze

  end # Constants

  module ClassMethods
    def find_by_hash arg, hash
      hash[:content_type_obj] = 
        content_type = 
        ContentType.find_by_hash(:first, hash)
      # $stderr.puts "  content_type = #{content_type.inspect}"
      hash[:content_type_id] = content_type && content_type.id
      
      raise ArgumentError, "content_type cannot be found for #{hash.inspect}" unless hash[:content_type_id]
      
      # $stderr.puts "  #{self}.find_by_hash(#{arg.inspect}, #{hash.inspect})"
      conditions = 
        case hash[:content_key]
        when ActiveRecord::Base
          [
           'id = ? AND content_type_id = ?',
           hash[:content_key].id,
           hash[:content_type_id]
          ]
        else
          [
           '(code = ? OR uuid = ?) AND content_type_id = ?', 
           hash[:content_key], 
           hash[:content_key_uuid],
           hash[:content_type_id]
          ]
        end
      
      obj = ModelCache.cache_for self, :find_by_hash, [ arg, conditions ] do
        find(arg, :conditions => conditions)
      end
      
      # $stderr.puts "  #{self}.find_by_hash(#{arg.inspect}, #{hash.inspect}) =>\n    #{obj.inspect}"
      obj
    end


    def create_from_hash hash
      unless obj = find_by_hash(:first, hash)
        # $stderr.puts "  hash[:content_type_obj] = #{hash[:content_type_obj].class.ancestors.inspect}"
        obj = create!(:code => hash[:content_key], 
                      :content_type_id => hash[:content_type_id])
      end
      obj
    end


    def load_from_hash hash
      hash = hash.dup # find_by_hash mutates hash
      unless obj = find_by_hash(:first, hash)
        obj = create!(:code => hash[:content_key], 
                      :content_type_id => hash[:content_type_id])
      end
      obj
    end
   
  end # ClassMethods


  module InstanceMethods
    def validate_code_with_content_type!
      if content_type
        unless content_type.key_regexp_rx.match(code)
          errors.add(:code, "Invalid code for content type #{content_type.code.inspect}")
        end
      end
    end


    def initialize_defaults!
      self.name ||= ''
      self.description ||= ''
    end


    def add_to_hash hash = { }
      hash[:content_key] = code
      # hash[:content_key_uuid] = initialize_uuid!
      hash[:content_type] = content_type.code
      hash
    end

    def to_s
      code
    end
  end # InstanceMethods


  Constants.constants.each do | c |
    v = Constants.const_get(c)
    # $stderr.puts "#{self}::#{c} => #{v.inspect}"
    self.const_set(c, v)
  end

end



