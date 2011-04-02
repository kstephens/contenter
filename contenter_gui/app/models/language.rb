#
# Represents a language with a unique ISO 2-letter code.
#
# '_' can be used as a wildcard.
#
class Language < ActiveRecord::Base
  include ContentModel
  include AuxDataModel
  include ContentAxis

  validates_format_of :code, :with => /\A([a-z_][a-z0-9_]+|_)\Z/, :message => "#{self.name} code is invalid"
  validates_uniqueness_of :code

end
