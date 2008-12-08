#
# Represents a language with a unique ISO 2-letter code.
#
# '_' can be used as a wildcard.
#
class Language < ActiveRecord::Base
  include ContentModel

  validates_format_of :code, :with => /\A([a-z_][a-z0-9_]+|_)\Z/
  validates_uniqueness_of :code

end
