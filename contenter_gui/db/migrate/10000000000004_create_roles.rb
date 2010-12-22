class CreateRoles < ActiveRecord::Migration
  def self.up
    tn = :roles
    create_table tn do |t|
      t.integer :lock_version, :null => false
      t.string :name, :null => false
      t.string :description, :null => false
      t.timestamps
    end
    add_index tn, :name, :unique => true

    # roles->parent_roles join table
    tn = :role_inheritances
    create_table tn do |t|
      t.integer :child_role_id, :null => false, :references => :roles
      t.integer :parent_role_id, :null => false, :references => :roles
      t.integer :sequence, :null => false
      t.timestamps
    end
    add_index tn, :child_role_id
    add_index tn, :parent_role_id
    add_index tn, [ :child_role_id, :parent_role_id ], :unique => true

    # roles->users join table
    tn = :role_users
    create_table tn do |t|
      t.integer :role_id, :null => false
      t.integer :user_id, :null => false
      t.integer :sequence, :null => false
      t.timestamps
    end
    add_index tn, :role_id
    add_index tn, :user_id
    add_index tn, [ :role_id, :user_id ], :unique => true
  end

  def self.down
    drop_table :roles
    drop_table :roles_users # role_users
    drop_table :roles_inheritances
  end
end
