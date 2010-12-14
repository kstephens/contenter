class CreateContentTypes < ActiveRecord::Migration
  def self.up
    create_table :mime_types do | t |
      t.column :lock_version, :integer,
        :null => false
      t.column :code, :string,
        :null => false
      t.column :name, :string,
        :null => false
      t.column :description, :string,
        :null => false
      t.column :aux_data, :binary,
        :null => false
      t.column :mime_type_super_id, :integer,
        :null => true, :references => :mime_types
      UserTracking.add_columns(t)
    end

    add_index :mime_types,
      :code, 
      :unique => true

    #######################################################

    create_table :content_types do |t|
      t.column :lock_version, :integer,
        :null => false
      t.column :code, :string,
        :null => false
      t.column :name, :string,
        :null => false
      t.column :plugin, :string,
        :null => false
      t.column :description, :string,
        :null => false
      t.column :key_regexp, :string,
        :null => false
      t.column :mime_type_id, :integer,
        :null => false
      t.column :aux_data, :binary,
        :null => false
      UserTracking.add_columns(t)
    end

    add_index :content_types,
      :code, 
      :unique => true

  end

  def self.down
    drop_table :mime_types

    drop_table :content_types
  end
end
