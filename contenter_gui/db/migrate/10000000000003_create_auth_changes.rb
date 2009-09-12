class CreateAuthChanges < ActiveRecord::Migration
  def self.up
    tn = :auth_changes
    create_table tn do |t|
      t.integer :user_id, :null => true
      t.time :changed_at, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :auth_changes
  end
end

