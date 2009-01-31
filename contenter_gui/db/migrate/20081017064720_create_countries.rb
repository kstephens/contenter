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
      t.column :creator_user_id, :integer,
        :null => false
      t.column :updater_user_id, :integer,
        :null => true
      t.timestamps
    end

    add_index :countries,
      :code,
      :unique => true

    [
     [ '_',  'Any Country', 'Wildcard' ],
     [ 'US', 'United States of America' ],
     [ 'GB', 'Great Britain' ],
     [ 'AU', 'Australia' ],
    ].each do | r |
      Country.
        create!(:code => r[0], 
                :name => r[1], 
                :description => r[2] || '')
    end
  end

  def self.down
    drop_table :countries
  end
end
