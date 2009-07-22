class CreateRevision < ActiveRecord::Migration
  def self.up
    create_table :version_lists do | t |
      t.column :lock_version, :integer,
        :null => false
      t.column :comment, :string, 
        :null => false
      UserTracking.add_columns t
    end

    create_table :version_list_names do | t |
      t.column :name, :string, 
        :null => false
      t.column :description, :string, 
        :null => false
      t.column :version_list_id, :integer,
        :null => true
      UserTracking.add_columns t
    end
    VersionListName.create_versioned_table

    add_index :version_list_names, 
    [ :name ],
    :unique => true

    add_index :version_list_names, 
    [ :version_list_id ],
    :unique => false

    # Join table between VersionList and Content
    tn = :version_list_contents
    create_table tn do | t |
      t.column :version_list_id, :integer, 
        :null => false
      t.column :content_version_id, :integer, 
        :null => false
    end

    add_index tn, 
    [ :version_list_id ],
    :unique => false

    add_index tn, 
    [ :content_version_id ],
    :unique => false

    add_index tn,
    [ :version_list_id, :content_version_id ],
    :name => :version_list_u,
    :unique => true

    VersionList.after(:comment => 'Initial Empty Version List') do
      # NOTHING!
    end
  end

  def self.down
    drop_table :version_list
    VersionListName.drop_versioned_table
    drop_table :version_list_name
    drop_table :version_list_content
  end
end

