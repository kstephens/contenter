class CreateApplications < ActiveRecord::Migration
  def self.up
    create_table :applications do |t|
      t.column :lock_version, :integer,
        :null => false
      t.column :code, :string,
        :null => false
      t.column :name, :string,
        :null => false
      t.column :description, :string,
        :null => false
      t.column :aux_data, :text,
        :null => false
      UserTracking.add_columns(t)
    end

    add_index :applications,
      :code,
      :unique => true
  end

  def self.down
    drop_table :applications
  end
end
