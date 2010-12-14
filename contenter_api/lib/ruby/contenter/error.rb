require 'contenter'


module Contenter
  # Generic base class for Contenter exceptions.
  class Error < ::Exception
    # General configuration error.
    class Configuration < self; end
    
    # Subclass needs to implement a method.
    class SubclassResponsibility < self; end
    
    # Content not found.
    class NotFound < self; end
    
    # Content not available.
    class Unknown < NotFound; end
    UnknownContent = Unknown
    
    # Request is ambiguous.
    # There is more than one entity that matches.
    class Ambiguous < NotFound; end
    AmbiguousContent = Ambiguous
    
    # Raised when an edit is attempted on a version that is older.
    class VersionConflict < self; end

    # Input is invalid.
    class InvalidInput < self; end
    Input = InvalidInput

    # Invalid API version.
    class InvalidAPIVersion < self; end

    # Internal Timeout.
    class Timeout < self; end

    class Auth < self;
      class NotAuthenticated < self; end
      class NotAuthorized < self; end
    end # class
  end # class

end # module

