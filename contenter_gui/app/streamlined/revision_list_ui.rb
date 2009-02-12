module RevisionListAdditions
end
RevisionList.class_eval { include RevisionListAdditions }

Streamlined.ui_for(RevisionList) do
  extend UserTrackingUiHelper

  default_order_options :order => "id DESC"

  c = 
    [
     :id,
     :comment,
    ]
  c += list_columns_user_tracking
  c +=
    [
     :content_versions, {
       :edit_in_list => false,
       :link_to => { :controller => :content_versions, :action => :show }
     }
    ]
  list_columns *c


  c = 
    [
     :id,
     :comment,
    ],
  c += show_columns_user_tracking
  c +=
    [
     :content_versions, {
       :show_view => 
       [
        :link, { :controller => :content_versions, :action => :show }
       ]
     }
    ]

  show_columns *c


  edit_columns \
  :comment, 
  :revision_list_contents

end
