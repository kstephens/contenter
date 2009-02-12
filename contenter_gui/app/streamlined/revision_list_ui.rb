module RevisionListAdditions
  def streamlined_name *args
    id.to_s
  end
end
RevisionList.class_eval { include RevisionListAdditions }

Streamlined.ui_for(RevisionList) do
  extend UserTrackingUiHelper

  default_order_options :order => "id DESC"

  c = 
    [
     :id, {
       :link_to => { :action => :show },
     },
     :comment,
    ]
  c += list_columns_user_tracking
  c +=
    [
     :revision_list_names, {
       :human_name => 'RLNs',
       :edit_in_list => false,
# Streamlined is annoying!
#       :list_view =>
#       [
#         :list, { 
#          :fields => [ :name ],
#          :link_to => { :controller => :revision_list_names, :action => :show },
#        },
#       ],
     },
     :content_versions, {
       :edit_in_list => false,
       :link_to => { :controller => :content_versions, :action => :show },
     },
    ]
  list_columns *c


  c = 
    [
     :id,
     :comment,
    ]
  c += show_columns_user_tracking
  c +=
    [
     :revision_list_names, {
       :human_name => 'RLNs',
       :show_view =>
       [
        :list, { 
          :fields => [ :name ],
          :link_to => { :controller => :revision_list_names, :action => :show },
        },
       ],
     },
     :content_versions, {
       :show_view => 
       [
        :link, { :controller => :content_versions, :action => :show },
       ],
     },
    ]
  show_columns *c


  edit_columns \
  :comment, 
  :revision_list_names

  footer_partials :show => 'content_versions'
end
