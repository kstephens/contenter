class Capability < ActiveRecord::Base
  include AuthCacheMethods

  validates_format_of :name, :with => /\A([a-z0-9_]+|\*|\+)(\/([a-z0-9_]+|\*|\+))*\Z/i
  validates_presence_of :name
  validates_presence_of :description

end
