class CreateApplications < ActiveRecord::Migration
  def self.up
    create_table :applications do |t|
      t.column :lock_version, :integer,
        :null => false
      t.column :code, :string,
        :null => true
      t.column :name, :string,
        :null => true
      t.column :description, :string,
        :null => true
      t.column :creator_user_id, :integer,
        :null => false, :references => :users
      t.column :updater_user_id, :integer,
        :null => true, :references => :users
      t.timestamps
    end

    add_index :applications,
      :code,
      :unique => true
  end

  def self.down
    drop_table :applications
  end
end
