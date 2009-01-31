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
      t.column :data, :binary, 
        :null => false
      t.column :creator_user_id, :integer,
        :null => false
      t.column :updater_user_id, :integer,
        :null => true
      t.timestamps
    end
    if Content::USE_VERSION
      Content.create_versioned_table
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
