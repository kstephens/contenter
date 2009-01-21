require 'contenter'


module Contenter
  # Generic base class for Contenter exceptions.
  class Error < ::Exception
    # General configuration error.
    class Configuration < self; end
    
    # Subclass needs to implement a method.
    class SubclassResponsibility < self; end
    
    # Content not available.
    class UnknownContent < self; end
    
    # Content request is ambiguous.
    # There is more than one content entity that matches.
    class AmbiguousContent < self; end
    
    # Raised when an edit is attempted on a version that is older.
    class VersionConflict < self; end

    # Input is invalid.
    class InvalidInput < self; end

    # Invalid API version.
    class InvalidAPIVersion < self; end
  end # class
  
end # module

