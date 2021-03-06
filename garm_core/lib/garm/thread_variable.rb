require 'garm'

module Garm

# Adds Thread-based class and instance variables.
module ThreadVariable
  def self.included base
    super
    base.instance_eval do
      extend ClassMethods
    end
  end

  module ClassMethods
    # Defines a class attribute stored in Thread.current.
    def cattr_accessor_thread *names
      cattr_getter_thread *names
      cattr_setter_thread *names
    end


    # Defines a class attribute setter stored in Thread.current.
    def cattr_setter_thread *names
      opts = Hash === names[-1] ? names.pop : EMPTY_HASH

      transform = opts[:setter_transform]
      transform = "__val = (#{transform})" if transform

      names.each do | name |
        instance_eval(expr = <<"END", __FILE__, __LINE__)
def self.#{name}= __val
  #{transform}
  Thread.current[:'#{self.name}.#{name}'] = [ __val ]
end
END
        # $stderr.puts "#{expr}"
      end
    end

    # Defines a class attribute getter stored in Thread.current.
    #
    # Options:
    #
    #   :initialize -- String: expression to initialize the variable is undefined.
    #   :default    -- String: expression to return if the variable value if undefined.
    #   :transform  -- String: expression to transform the __val variable before returning.
    #
    # Also defines clear_NAME method that undefines the thread variable.
    def cattr_getter_thread *names
      opts = Hash === names[-1] ? names.pop : EMPTY_HASH
      
      initialize = opts[:initialize]
      initialize = "||= [ #{initialize} ]" if initialize

      default = opts[:default]
      default = "__val ||= [ #{default} ]" if default

      transform = opts[:transform]
      transform = "__val = (#{transform})" if transform

      names.each do | name |
        instance_eval(expr = <<"END", __FILE__, __LINE__)
def self.clear_#{name}
  Thread.current[:'#{self.name}.#{name}'] = nil
end

def self.#{name}
  __val = Thread.current[:'#{self.name}.#{name}'] #{initialize}
  #{default}
  __val = __val && __val.first
  #{transform}
  __val
end
END
        # $stderr.puts "#{expr}"
      end
    end

    def attr_accessor_thread *names
      attr_getter_thread *names
      attr_setter_thread *names
    end

    def attr_setter_thread *names
      opts = Hash === names[-1] ? names.pop : EMPTY_HASH

      transform = opts[:setter_transform]
      transform = "__val = (#{transform})" if transform

      names.each do | name |
        instance_eval <<"END", __FILE__, __LINE__
def #{name}= __val
  #{transform}
  (Thread.current[:'#{self.name}\##{name}'] ||= { })[self.id] = [ __val ]
end
END
      end
    end

    def attr_getter_thread *names
      opts = Hash === names[-1] ? names.pop : EMPTY_HASH

      initialize = opts[:initialize]
      if initialize
        pre_default = "__val[self.id] ||= [ #{initialize} ]"
        initialize = "||= { }"
      else
        pre_default = "__val &&= __val[self.id]"
      end

      default = opts[:default]
      default = "__val ||= [ #{default} ]" if default

      transform = opts[:transform]
      transform = "__val = (#{transform})" if transform

      names.each do | name |
        instance_eval <<"END", __FILE__, __LINE__
def #{name}
  __val = (Thread.current[:'#{self.name}\##{name}'] #{initialize})
  #{pre_default}
  #{default}
  __val = __val && __val.first
  #{transform}
  __val
end
END
      end
    end

  end # module
end # module

end # module
