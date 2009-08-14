class CreateBrands < ActiveRecord::Migration
  def self.up
    create_table :brands do |t|
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

    add_index :brands,
      :code,
      :unique => true

    [
     [ '_',   'Any Brand',     'Wildcard Brand' ],
     [ 'test',  'Test Brand', 'Test brand' ],
    ].each do | r |
      Brand.
        create!(:code => r[0], 
                :name => r[1], 
                :description => r[2] || '')
    end

  end

  def self.down
    drop_table :brands
  end
end
