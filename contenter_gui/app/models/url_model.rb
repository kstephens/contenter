module UrlModel
  # A getter for the non-rooted URL of a model object
  def url
    return nil unless self.id
    "#{self.class.name.underscore.pluralize}/show/#{self.id}"
  end
end
