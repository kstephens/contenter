#
# Represents the association between
# a RevisionList and ContentKey.
#
class RevisionListContentKey < ActiveRecord::Base

  belongs_to :revision_list
  belongs_to :content_key_version, :class_name => 'ContentKey::Version'

  validates_presence_of :revision_list
  validates_presence_of :content_key_version

end


