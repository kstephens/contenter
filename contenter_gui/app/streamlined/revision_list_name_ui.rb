module RevisionListNameAdditions
end
RevisionListName.class_eval { include RevisionListNameAdditions }

Streamlined.ui_for(RevisionListName) do
  default_order_options :order => "name"

  list_columns \
  :name, {
    :link_to => { :action => :show },
  }, 
  :creator, {
    :edit_in_list => false,
    :link_to => { :controllers => :users, :action => :show },
  },
  :created_at, 
  :updater, {
    :edit_in_list => false,
    :link_to => { :controllers => :users, :action => :show },
  }, 
  :updated_at,
  :version

  show_columns \
  :name,
  :description, 
  :creator, {
    :link_to => { :controller => :users, :action => :show },
  }, 
  :created_at, 
  :updater, {
    :link_to => { :controller => :users, :action => :show },
  },
  :updated_at, 
  :revision_list, {
    :link_to => { :controller => :revision_lists, :action => :show }
  }

  edit_columns \
  :name, \
  :description, \
  :revision_list, {
    :link_to => { :controller => :revision_lists, :action => :show }
  }


end   
