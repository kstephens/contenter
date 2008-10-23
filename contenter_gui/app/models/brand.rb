class Brand < ActiveRecord::Base

  validates_format_of :code, :with => /\A([A-Z_][A-Z0-9_]+|_)*\Z/
  validates_uniqueness_of :code

end
