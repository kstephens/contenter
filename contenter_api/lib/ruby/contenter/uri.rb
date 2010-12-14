require 'contenter'

require 'open-uri'
require 'uri'

module Contenter
  # Support for URI.parse('file:///dir/file').read.
  module URIFileSupport
    FILE_SCHEME = 'file'.freeze
    def read
      case scheme
      when FILE_SCHEME
        file = to_s.sub(%r{\Afile:(//[^/]+)?}, '')
        # Pretend to be a webserver by handling %XX escapes?
        # require 'cgi'
        # file = CGI.unescape(file)
        File.read(file)
      else
        raise NoMethodError, "undefined method `read' for #{inspect}"
      end
    end
  end
end

URI::Generic.class_eval do 
  include Contenter::URIFileSupport
end
