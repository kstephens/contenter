# Create role_inheritances table for inheritable roles.
# See also 100*4_create_roles.rb.
class CreateRoleInheritancesTable < ActiveRecord::Migration
  def self.up
    return unless RAILS_ENV != 'development' || ENV['FORCE_MIGRATION']
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
  end
  
  def self.down
    drop_table :roles_inheritances
  end
end
