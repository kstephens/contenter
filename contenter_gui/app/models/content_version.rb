# Streamlined alias for act_as_versioned class generated
# for Content.
ContentVersion = Content::Version

Content::Version.class_eval do
  include ContentAdditions
  include UserTracking

  Content::BELONGS_TO.each do | x |
    belongs_to x
    validates_presence_of x
  end

  # created_at columns are not propaged to act_as_versioned generated classes.
  def created_at
    content.created_at
  end
end

