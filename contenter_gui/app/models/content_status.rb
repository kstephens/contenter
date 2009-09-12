
#
# Represents a content status.
#
class ContentStatus < ActiveRecord::Base
  include ContentModel

  validates_format_of :code, :with => /\A([A-Z_][A-Z0-9_]+|_)\Z/i
  validates_uniqueness_of :code

  validates_format_of :name, :with => /\A([A-Z_][A-Z0-9_]+|_)\Z/i
  validates_uniqueness_of :name

end

