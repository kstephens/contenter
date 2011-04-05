# Create role_inheritances table for inheritable roles.
# See also 100*4_create_roles.rb.
class CreateRoleUsersTable < ActiveRecord::Migration
  def self.up
    return unless RAILS_ENV != 'development' || ENV['FORCE_MIGRATION']
    # roles->users join table
    tn = :role_users
    rename_table "roles_users", tn
    change_table tn do | t |
      t.integer :sequence, :null => false, :default => 1
    end
  end
  
  def self.down
    raise 'Not revertable.'
  end
end

