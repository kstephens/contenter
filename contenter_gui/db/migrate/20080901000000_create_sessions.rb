class CreateSessions < ActiveRecord::Migration
  def self.up
    create_table :sessions do |t|
      t.string :session_id, :null => false
      t.text :data
      t.integer :user_id, :null => true
      t.timestamps
    end

    add_index :sessions, :session_id
    add_index :sessions, :updated_at
    add_index :sessions, :user_id
  end

  def self.down
    drop_table :sessions
  end
end
