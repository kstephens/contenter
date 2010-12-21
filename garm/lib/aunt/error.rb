require 'aunt'


module Aunt
  # Generic base class for Aunt exceptions.
  class Error < ::Exception
    # General configuration error.
    class Configuration < self; end
    
    # Subclass needs to implement a method.
    class SubclassResponsibility < self; end
    
    # Input is invalid.
    class InvalidInput < self; end
    Input = InvalidInput

    # Invalid API version.
    class InvalidAPIVersion < self; end

    # Internal Timeout.
    class Timeout < self; end

    class NotAuthenticated < self; end
    class NotAuthorized < self; end
  end # class

end # module

