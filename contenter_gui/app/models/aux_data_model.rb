require 'yaml'

# Mixin support for arbitrary data Hash column.
# Also allows access to raw YAML data.
module AuxDataModel
  def self.included target
    super
    target.extend(ClassMethods)
    target.class_eval do 
      include InstanceMethods

      # serialize :aux_data # arbitrary data Hash.

      before_validation :initialize_aux_data!
    end
  end

  module ClassMethods
  end # module

  module InstanceMethods
    AUX_DATA = 'aux_data'.freeze

    def initialize_aux_data!
      self.aux_data ||= { }
      self.aux_data_yaml
    end

    def reload
      @aux_data = @aux_data_ = nil
      super
    end

    def aux_data_yaml= x
      # debugger
      if read_attribute(AUX_DATA) != x
        write_attribute(AUX_DATA, x)
        @aux_data_ = false
        @aux_data = nil
      end
    end

    def aux_data_yaml
      unless @aux_data_yaml_
        write_attribute(AUX_DATA, YAML::dump(aux_data))
        @aux_data_yaml_ = true
      end
      read_attribute(AUX_DATA)
    end

    def aux_data= data
      @aux_data_ = true
      @aux_data = data
      @aux_data_yaml_ = false
    end

    def aux_data
      unless @aux_data_
        x = read_attribute(AUX_DATA)
        @aux_data = x && YAML::load(x)
        @aux_data_ = true
      end
      @aux_data
    end
  end # module
end

