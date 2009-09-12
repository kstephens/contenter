class CreateContents < ActiveRecord::Migration
  def self.up
    create_table :contents do |t|
      t.column :uuid, :string, 
        :limit => 36,
        :null => false
      t.column :content_key_id, :integer, 
        :null => false
      t.column :language_id, :integer, 
        :null => false
      t.column :country_id, :integer, 
        :null => false
      t.column :brand_id, :integer, 
        :null => false
      t.column :application_id, :integer, 
        :null => false
      t.column :mime_type_id, :integer, 
        :null => false
      t.column :md5sum, :string,
        :limit => 32,
        :null => false
      t.column :data, :binary,
        :null => false
      UserTracking.add_columns t
    end

    ENV.delete("NO_INTROSPECTION")
    Content.create_versioned_table
    # Ensure the db populates these columns
    execute("ALTER TABLE content_versions ALTER COLUMN created_at SET DEFAULT NOW();")     
    add_index :content_versions, :created_at, :unique => false

    add_index :contents,
      [ :uuid ], 
      :unique => true

    add_index :contents,
    [ 
     :content_key_id,
     :language_id,
     :country_id,
     :brand_id,
     :application_id,
     :mime_type_id,
    ],
    :name => :contents_u, 
    :unique => true
  end

  def self.down
    Content.drop_versioned_table
    drop_table :contents
  end
end
