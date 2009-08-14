class CreateLanguages < ActiveRecord::Migration
  def self.up
    create_table :languages do |t|
      t.column :lock_version, :integer,
        :null => false
      t.column :code, :string,
        :null => false
      t.column :name, :string,
        :null => false
      t.column :description, :string,
        :null => false
      t.column :creator_user_id, :integer,
        :null => false
      t.column :updater_user_id, :integer,
        :null => true
      t.timestamps
    end

    add_index :languages,
      :code,
      :unique => true

  end

  def self.down
    drop_table :languages
  end
end
