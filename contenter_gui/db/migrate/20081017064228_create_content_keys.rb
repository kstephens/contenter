class CreateContentKeys < ActiveRecord::Migration
  def self.up
    create_table :content_keys do |t|
      t.column :uuid, :string, 
        :size => 36,
        :null => false
      t.column :code, :string, 
        :null => false
      t.column :name, :string, 
        :null => false
      t.column :description, :string, 
        :null => false
      t.column :data, :text, 
        :null => false
      t.column :content_type_id, :integer, 
        :null => false
      t.timestamps
    end

    add_index :content_keys,
      [ :uuid ], 
      :unique => true

    add_index :content_keys,
      [ :code, :content_type_id ], 
      :unique => true
  end

  def self.down
    drop_table :content_keys
  end
end

