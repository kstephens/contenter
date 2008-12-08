class CreateContents < ActiveRecord::Migration
  def self.up
    create_table :contents do |t|
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
      t.column :content, :text, 
        :null => false
      t.timestamps
    end

    add_index :contents,
    [ 
     :content_key_id,
     :language_id,
     :country_id,
     :brand_id,
     :application_id,
    ],
    :name => :contents_u, 
    :unique => true
  end

  def self.down
    drop_table :contents
  end
end
