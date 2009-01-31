class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table "users", :force => true do |t|
      t.column :login,                     :string, :limit => 40, :null => false
      t.column :name,                      :string, :limit => 100, :default => '', :null => true
      t.column :email,                     :string, :limit => 100, :null => false
      t.column :crypted_password,          :string, :limit => 40, :null => false
      t.column :salt,                      :string, :limit => 40, :null => false
      t.column :created_at,                :datetime, :null => false
      t.column :updated_at,                :datetime
      t.column :remember_token,            :string, :limit => 40
      t.column :remember_token_expires_at, :datetime

      # t.timestamps
    end
    add_index :users, :login, :unique => true
  end

  def self.down
    drop_table "users"
  end
end
