#
# Represents the association between
# a RevisionList and Content.
#
class RevisionListContent < ActiveRecord::Base

  belongs_to :revision_list
  belongs_to :content_version, :class_name => 'Content::Version'

end


