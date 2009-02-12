
module UserTrackingUiHelper
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


