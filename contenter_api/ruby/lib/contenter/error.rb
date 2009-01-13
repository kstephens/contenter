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
    # There is more than one content entity that matches
    # a unique key and selector.
    class AmbiguousContent < self; end
    
  end
  
end # module

