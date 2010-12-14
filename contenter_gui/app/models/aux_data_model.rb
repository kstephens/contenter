
# Mixin support for arbitrary data Hash column.
module AuxDataModel
  def self.included target
    super
    target.extend(ClassMethods)
    target.class_eval do 
      include InstanceMethods

      serialize :aux_data # arbitrary data Hash.

      before_validation :initialize_aux_data!
    end
  end

  module ClassMethods
  end # module

  module InstanceMethods
    def initialize_aux_data!
      self.aux_data ||= { } 
    end
  end # module
end

