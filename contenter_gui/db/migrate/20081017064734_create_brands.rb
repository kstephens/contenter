class CreateBrands < ActiveRecord::Migration
  def self.up
    create_table :brands do |t|
      t.column :code, :string,
        :null => false
      t.column :name, :string,
        :null => false
      t.column :description, :string,
        :null => false
      t.timestamps
    end

    add_index :brands,
      :code,
      :unique => true

    [
     [ '_',  'Any Brand' ],
     [ 'US',  'CNU US Brand' ],
     [ 'GB',  'CNU GB Brand' ],
     [ 'AEA', 'Advance America US JV Brand' ],
    ].each do | r |
      Brand.
        create(:code => r[0], 
               :name => r[1], 
               :description => r[2] || '')
    end

  end

  def self.down
    drop_table :brands
  end
end
