class Country < ActiveRecord::Base

  validates_format_of :code, :with => /\A([A-Z][A-Z]|_)\Z/
  validates_uniqueness_of :code
end
