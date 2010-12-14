
#
# Represents a unique application name.
#
# '_' can be used as a wildcard.
#
class Application < ActiveRecord::Base
  include ContentModel
  include AuxDataModel

  validates_format_of :code, :with => /\A([a-z_][a-z0-9_]+|_)\Z/i, :message => "#{self.name} code is invalid"
  validates_uniqueness_of :code

end
