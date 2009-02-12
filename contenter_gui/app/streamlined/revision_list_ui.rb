module RevisionListAdditions
  def streamlined_name *args
    #(name || id).to_s
    id.to_s
  end

  def version_count
    x = content_versions.size
    x == 0 ? '' : x
  end

  def rlns
    revision_list_names.map do | n |
      %Q{<a href="/revision_list_names/show/#{n.id}">#{n.name}</a>}
    end.join(', ')
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
# Streamlined is annoying!
=begin
     :revision_list_names, {
       :human_name => 'RLNs',
       :edit_in_list => false,

       :list_view =>
       [
         :list, { 
          :fields => [ :name ],
          :link_to => { :controller => :revision_list_names, :action => :show },
        },
       ],
     },
=end
     :version_count, {
       :human_name => 'Versions',
     },
     :rlns, {
       :human_name => 'RLNs',
       :allow_html => true,
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
     :version_count, {
       :human_name => 'Versions',
     },
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
    ]
  show_columns *c


  edit_columns \
  :comment, 
  :revision_list_names

  footer_partials :show => 'content_versions'
end
