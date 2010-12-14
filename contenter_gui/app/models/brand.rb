
#
# Represents unique content brand.
#
# '_' can be used as a wildcard.
#
class Brand < ActiveRecord::Base
  include ContentModel
  include AuxDataModel

  validates_format_of :code, :with => /\A([A-Z_][A-Z0-9_]+|_)\Z/i, :message => "#{self.name} code is invalid"
  validates_uniqueness_of :code

end
