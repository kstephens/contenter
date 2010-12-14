require 'contenter'

module Contenter
  module Regexp
    def uuid
      /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\Z/ # e.g. 9301c481-bc3c-4edc-8ce0-8dd66c097473
    end

      
    def md5sum
      /\A[0-9a-f]{32}\Z/
    end

    extend self
  end
end
