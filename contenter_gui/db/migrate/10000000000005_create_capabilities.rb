class CreateCapabilities < ActiveRecord::Migration
  def self.up
    tn = :capabilities
    create_table tn do |t|
      t.integer :lock_version, :null => false
      t.string :name, :null => false
      t.string :description, :null => false
      t.timestamps
    end
    
    add_index tn,
    :name,
    :unique => true

    # Generate the join table
    tn = :role_capabilities
    create_table tn do |t|
      t.integer :lock_version, :null => false
      t.integer :role_id, :capability_id, :null => false
      t.boolean :allow, :null => false
      t.timestamps
    end
    add_index tn, :role_id
    add_index tn, :capability_id

    add_index tn, 
    [ :role_id, :capability_id ], 
    :unique => true
  end

  def self.down
    drop_table :capabilities

    drop_table :role_capabilities
  end
end
