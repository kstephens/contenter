require 'contenter/uuid'

# Mixin support for uuid column
module UuidModel
  def self.included target
    super
    target.extend(ClassMethods)
    target.class_eval do 
      include InstanceMethods

      before_validation :initialize_uuid!

      validates_presence_of :uuid
      validates_format_of :uuid, :with => Contenter::Regexp.uuid
    end
  end

  module ClassMethods
=begin
    def uuid_column t, name = :uuid
      t.column name, :string, 
        :limit => 36,
        :null => false
    end
    def uuid_index t, name = :uuid
      add_index t, name, :unique => true
    end
=end
  end # module

  module InstanceMethods
    def initialize_uuid!
      self.uuid = Contenter::UUID.generate_random.downcase if self.uuid.blank?
    end
  end # module
end

