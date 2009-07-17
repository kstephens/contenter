module RevisionListNameAdditions
#  def revision_list_link
#    revision_list
#  end
end
RevisionListName.class_eval { include RevisionListNameAdditions }

Streamlined.ui_for(RevisionListName) do
  extend UserTrackingUiHelper

  default_order_options :order => "name"

  c =
    [
     :name, {
       :link_to => { :action => :show },
     }, 
    ]
  c += list_columns_user_tracking
  c += 
    [
     :version, {
       :filterable => false,
     },
     :revision_list, {
       :edit_in_list => false,
       :link_to => { :controller => :revision_lists, :action => :show },
     }, 
    ]

  list_columns *c

  c =
    [
     :name,
     :description,
    ]
  c += list_columns_user_tracking
  c +=
    [
     :version,
     :revision_list, {
       :show_view =>
       [
        :link, { :controller => :revision_lists, :action => :show },
       ]
     }
    ]
  show_columns *c

  c = 
    [
     :name,
     :description,
     :revision_list, {
       :link_to => { :controller => :revision_lists, :action => :show },
     }
    ]
  edit_columns *c


end   
