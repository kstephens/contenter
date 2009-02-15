# Streamlined alias for act_as_versioned class generated
# for ContentKey.
ContentKeyVersion = ContentKey::Version

ContentKey::Version.class_eval do
  include ContentAdditions
  include UserTracking

  ContentKey::BELONGS_TO.each do | x |
    belongs_to x
    validates_presence_of x
  end

  # created_at columns are not propaged to act_as_versioned generated classes.
  def created_at
    content_key.created_at
  end
end

