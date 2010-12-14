
#
# Represents a country with a unique ISO 2-letter code.
#
# '_' can be used as a wildcard.
#
class Country < ActiveRecord::Base
  include ContentModel
  include AuxDataModel

  validates_format_of :code, :with => /\A([A-Z][A-Z]|_)\Z/, :message => "#{self.name} code is invalid"
  validates_uniqueness_of :code
end

