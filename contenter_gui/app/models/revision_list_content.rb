#
# Represents the association between
# a RevisionList and Content.
#
class RevisionListContent < ActiveRecord::Base

  belongs_to :revision_list
  belongs_to :content # , :condition => 'contents.version = revision_list_contents.content_version'

end


