
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
     },
     :updater, {
       :edit_in_list => false,
       :link_to => { :controller => :users, :action => :show },
     },
     :updated_at, {
       :human_name => 'Updated',
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
     :created_at,
     :updater, {
       :show_view => 
       [
        :link, { :controller => :users, :action => :show },
       ]
     },
     :updated_at,
    ]
  end

  def edit_columns_user_tracking
    [
     ]
  end
end


