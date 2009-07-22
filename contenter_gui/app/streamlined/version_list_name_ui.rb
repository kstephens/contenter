module VersionListNameAdditions
#  def version_list_link
#    version_list
#  end
end
VersionListName.class_eval { include VersionListNameAdditions }

Streamlined.ui_for(VersionListName) do
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
     :version_list, {
       :edit_in_list => false,
       :link_to => { :controller => :version_lists, :action => :show },
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
     :version_list, {
       :show_view =>
       [
        :link, { :controller => :version_lists, :action => :show },
       ]
     }
    ]
  show_columns *c

  c = 
    [
     :name,
     :description,
     :version_list, {
       :link_to => { :controller => :version_lists, :action => :show },
     }
    ]
  edit_columns *c


end   
