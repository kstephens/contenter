class CreateContentTypes < ActiveRecord::Migration
  def self.up
    create_table :content_types do |t|
      t.column :lock_version, :integer,
        :null => false
      t.column :code, :string,
        :null => false
      t.column :name, :string,
        :null => false
      t.column :plugin, :string,
        :null => true
      t.column :description, :string,
        :null => false
      t.column :key_regexp, :string,
        :null => false
      t.column :creator_user_id, :integer,
        :null => false, :references => :users
      t.column :updater_user_id, :integer,
        :null => true, :references => :users
      t.timestamps
    end

    add_index :content_types,
      :code, 
      :unique => true

  end

  def self.down
    drop_table :content_types
  end
end
