class CreateRevision < ActiveRecord::Migration
  def self.up
    create_table :revision_lists do | t |
      t.column :lock_version, :integer,
        :null => false
      t.column :comment, :string, 
        :null => false
      UserTracking.add_columns t
    end

    create_table :revision_list_names do | t |
      t.column :name, :string, 
        :null => false
      t.column :description, :string, 
        :null => false
      t.column :revision_list_id, :integer,
        :null => true
      UserTracking.add_columns t
    end
    RevisionListName.create_versioned_table

    add_index :revision_list_names, 
    [ :name ],
    :unique => true

    add_index :revision_list_names, 
    [ :revision_list_id ],
    :unique => false

    # Join table between RevisionList and Content
    tn = :revision_list_contents
    create_table tn do | t |
      t.column :revision_list_id, :integer, 
        :null => false
      t.column :content_version_id, :integer, 
        :null => false
    end

    add_index tn, 
    [ :revision_list_id ],
    :unique => false

    add_index tn, 
    [ :content_version_id ],
    :unique => false

    add_index tn,
    [ :revision_list_id, :content_version_id ],
    :name => :revision_list_u,
    :unique => true

    RevisionList.after(:comment => 'Initial Empty Revision List') do
      # NOTHING!
    end
  end

  def self.down
    drop_table :revision_list
    RevisionListName.drop_versioned_table
    drop_table :revision_list_name
    drop_table :revision_list_content
  end
end

