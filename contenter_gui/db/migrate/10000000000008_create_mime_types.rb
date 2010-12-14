class CreateMimeTypes < ActiveRecord::Migration
  def self.up
    # Moved to *_create_content_types.rb
=begin
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
      UserTracking.add_columns(t)
    end

    add_index :mime_types,
      :code, 
      :unique => true
=end
  end

  def self.down
    # drop_table :mime_types
  end
end

