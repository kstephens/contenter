class CreateContents < ActiveRecord::Migration
  def self.up
    create_table :contents do |t|
      t.column :uuid, :string, 
        :size => 36,
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
        :size => 32,
        :null => false
      t.column :data, :binary,
        :null => false
      UserTracking.add_columns t
    end

    if Content::USE_VERSION
      Content.create_versioned_table
      # Bypass acts_as_versioned and let the db populate these columns
      execute("ALTER TABLE content_versions ADD COLUMN 
       created_at timestamp WITHOUT time zone NOT NULL DEFAULT NOW()")

      add_index :content_versions, :created_at, :unique => false
    end

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
    if Content::USE_VERSION
      Content.drop_versioned_table
    end
    drop_table :contents
  end
end
