class CreateKeyVersion < ActiveRecord::Migration
  def self.up
    # Rename lock_version to version for acts_as_versioned
    tn = :content_keys
    rename_column tn, :lock_version, :version

    # Create content_key_versions table for acts_as_versioned ContentKey::Version.
    ENV.delete("NO_INTROSPECTION")
    ContentKey.create_versioned_table
    
    # Ensure the db populates these columns
    execute("ALTER TABLE content_key_versions ALTER COLUMN created_at SET DEFAULT NOW();")

    add_index :content_key_versions, :created_at, :unique => false

    # Join table between VersionList and ContentKeys::Version.
    tn = :version_list_content_keys
    create_table tn do | t |
      t.column :version_list_id, :integer, 
        :null => false
      t.column :content_key_version_id, :integer, 
        :null => false
    end
    add_index tn,
    [ :version_list_id ],
    :unique => false

    add_index tn,
    [ :content_key_version_id ],
    :unique => false

    add_index tn,
    [ :version_list_id, :content_key_version_id ],
    :name => :version_list_key_u,
    :unique => true
  end

  def self.down
    tn = :version_list_content_keys
    drop_table :tn

    ContentVersion.drop_versioned_table

    tn = :content_types
    rename_column tn, :version, :lock_version
  end
end
