class CreateRoles < ActiveRecord::Migration
  def self.up
    tn = :roles
    create_table tn do |t|
      t.integer :lock_version
      t.string :name
      t.string :description
      t.timestamps
    end
    add_index tn, :name, :unique => true

    # generate the join table
    tn = :roles_users
    create_table tn, :id => false do |t|
      t.integer :role_id, :user_id
    end
    add_index tn, :role_id
    add_index tn, :user_id
    add_index tn, [ :role_id, :user_id ], :unique => true

  end

  def self.down
    drop_table :role
    drop_table :roles_users
  end
end
