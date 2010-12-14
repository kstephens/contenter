
module UserTrackingUiHelper
  def _list_field name, human_name = nil
    human_name ||= name.to_s.humanize
    {
      :human_name => human_name,
      :edit_in_list => false,
    }
  end

  def _show_field name, human_name = nil
    human_name ||= name.to_s.humanize
    {
      :human_name => human_name,
      :show_view =>
      [ :link, 
        {
          :fields => [ :code ],
        }
      ],
    }
  end

  # FIXME: Generates incorrect links!
  def list_columns_user_tracking
    [
     :creator, {
       :edit_in_list => false,
       :link_to => { :controller => :users, :action => :show },
     },
     :created_at, {
       :human_name => 'Created',
       :filterable => false,
     },
     :updater, {
       :edit_in_list => false,
       :link_to => { :controller => :users, :action => :show },
     },
     :updated_at, {
       :human_name => 'Updated',
       :filterable => false,
     },
    ]
  end

  def show_columns_user_tracking
    [
     :creator, {
       :show_view =>
       [
        :link, { :controller => :users, :action => :show },
       ]
     }, 
     :created_at, {
       :filterable => false,
     },
     :updater, {
       :show_view => 
       [
        :link, { :controller => :users, :action => :show },
       ]
     },
     :updated_at, {
       :filterable => false,
     },
    ]
  end

  def edit_columns_user_tracking
    [
     ]
  end
end


