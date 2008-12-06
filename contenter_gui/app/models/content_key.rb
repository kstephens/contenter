class ContentKey < ActiveRecord::Base

  belongs_to :content_type
  validates_presense_of :content_type_id

  validates_format_of :code, :with => /\A([a-z_][a-z0-9_]*)\Z/
  validates_uniqueness_of [ :code, :content_type_id ]

end
