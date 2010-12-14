class CreateContentConversions < ActiveRecord::Migration
  TABLE = :content_conversions
  def self.up
    create_table TABLE do | t |
      t.column :lock_version, :integer,
        :null => false

      t.column :uuid, :string, 
        :limit => 36,
        :null => false

      t.column :src_uuid, :string, 
        :limit => 36,
        :null => true
      t.column :src_data, :binary,
        :null => false
      t.column :src_data_md5sum, :string,
        :null => false, :limit => 32
      t.column :src_mime_type, :string,
        :null => false
      t.column :src_options, :text,
        :null => false

      t.column :dst_uuid, :string, 
        :limit => 36,
        :null => true
      t.column :dst_data, :binary,
        :null => false
      t.column :dst_data_md5sum, :string,
        :null => false, :limit => 32
      t.column :dst_mime_type, :string,
        :null => false
      t.column :dst_options, :text,
        :null => false

      UserTracking.add_columns(t)
    end

    add_index TABLE,
      :src_uuid,
      :unique => false

    add_index TABLE,
      :dst_uuid,
      :unique => false
    
    add_index TABLE,
      :src_data_md5sum, 
      :unique => false

    add_index TABLE,
      [ :src_data_md5sum, :src_mime_type, :dst_uuid, :dst_mime_type, :dst_options, ],
      :unique => true
  end

  def self.down
    drop_table TABLE
  end
end


