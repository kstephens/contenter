class CreateKeyVersion < ActiveRecord::Migration
  def self.up

    # Create content_key_versions table for acts_as_versioned ContentKey::Version.
    ContentKey.create_versioned_table
    
    # Ensure the db populates these columns
    execute("ALTER TABLE content_key_versions ALTER COLUMN created_at SET DEFAULT NOW();")

    add_index :content_key_versions, :created_at, :unique => false

  end

  def self.down
    tn = :version_list_content_keys
    drop_table :tn

    ContentVersion.drop_versioned_table

    tn = :content_types
    rename_column tn, :version, :lock_version
  end
end
