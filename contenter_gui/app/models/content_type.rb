
#
# Represents a unique content type.
#
class ContentType < ActiveRecord::Base
  include ContentModel

  validates_format_of :code, :with => /\A([a-z_][a-z0-9_]*)\Z/
  validates_uniqueness_of :code

end
