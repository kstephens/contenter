class CreateContentStatus < ActiveRecord::Migration
  TABLE = "content_statuses"
  def self.up
    create_table TABLE, :force => true do | t |
      t.column :code,                      :string, :limit => 32, :null => false
      t.column :name,                      :string, :limit => 100, :null => false
      t.column :description,               :string, :limit => 255, :null => false
      UserTracking.add_columns t
    end
    add_index TABLE, :code, :unique => true
 
    Contenter::Seeder.new.core_content_status! if RAILS_ENV == 'production'

    [ Content, Content::Version ].each do | cls |
      table = cls.table_name
      add_column table, :content_status_id, :integer, :default => 1, :null => false
      add_index table, :content_status_id
    end

   end

  def self.down
    drop_table TABLE

    [ Content, Content::Version ].each do | cls |
      table = cls.table_name
      remove_column table, :content_status_id
    end
  end
end
