
#
# Represents a unique MIME type.
#
# '_' can be used as a wildcard.
#
class MimeType < ActiveRecord::Base
  include ContentModel

  validates_format_of :code, :with => /\A_|([a-z_][a-z0-9_]*)\/([a-z_][a-z0-9_]*)\Z/
  validates_uniqueness_of :code
end

