module VersionListAdditions
  def streamlined_name *args
    #(name || id).to_s
    id.to_s
  end

  def content_version_count
    x = content_versions.size
    x == 0 ? '' : x
  end

  def content_key_version_count
    x = content_key_versions.size
    x == 0 ? '' : x
  end

  def rlns
    version_list_names.map do | n |
      %Q{<a href="/version_list_names/show/#{n.id}">#{n.name}</a>}
    end.join(', ')
  end
end
VersionList.class_eval { include VersionListAdditions }

Streamlined.ui_for(VersionList) do
  extend UserTrackingUiHelper

  quick_delete_button false

  default_order_options :order => "id DESC"

  c = 
    [
     :id, {
       :link_to => { :action => :show },
       :filterable => false,
     },
     :comment,
    ]
  c += list_columns_user_tracking
  c +=
    [
     :content_version_count, {
       :human_name => 'Content Versions',
     },
     :content_key_version_count, {
       :human_name => 'Key Versions',
     },
     :rlns, {
       :human_name => 'Names',
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
     :content_version_count, {
       :human_name => 'Content Versions',
     },
     :content_key_version_count, {
       :human_name => 'Key Versions',
     },
     :version_list_names, {
       :human_name => 'Names',
       :show_view =>
       [
        :list, { 
          :fields => [ :name ],
          :link_to => { :controller => :version_list_names, :action => :show },
        },
       ],
     },
    ]
  show_columns *c

  edit_columns \
  :comment, 
  :version_list_names

  footer_partials :show => 'shared/related'

end
