class CreateCountries < ActiveRecord::Migration
  def self.up
    create_table :countries do |t|
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

    add_index :countries,
      :code,
      :unique => true

  end

  def self.down
    drop_table :countries
  end
end
