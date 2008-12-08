
#
# Represents a unique MIME type.
#
class MimeType < ActiveRecord::Base
  include ContentModel

  validates_format_of :code, :with => /\A([a-z_][a-z0-9_]*)\/([a-z_][a-z0-9_]*)\Z/
  validates_uniqueness_of :code

end

