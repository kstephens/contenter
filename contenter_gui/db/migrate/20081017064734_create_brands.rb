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
     [ '_',   'Any Brand',     'Wildcard Brand' ],
     [ 'US',  'CNU US Brand', 'cashnetusa.com' ],
     [ 'GB',  'CNU GB Brand', 'quickquid.co.uk' ],
     [ 'AEA', 'Advance America US JV Brand', 'applyadvanceamerica.com' ],
     [ 'AU',  'CNU AU Brand', 'TBD' ]
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
