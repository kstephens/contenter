class Language < ActiveRecord::Base

  validates_format_of :code, :with => /\A([a-z_][a-z0-9_]+|_)\Z/
  validates_uniqueness_of :code

end
