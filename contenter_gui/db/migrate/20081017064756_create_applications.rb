class CreateApplications < ActiveRecord::Migration
  def self.up
    create_table :applications do |t|
      t.column :lock_version, :integer,
        :null => false
      t.column :code, :string,
        :null => true
      t.column :name, :string,
        :null => true
      t.column :description, :string,
        :null => true
      t.timestamps
    end

    add_index :applications,
      :code,
      :unique => true

    [
     [ '_', 'Any Application', 'Wildcard' ],
     [ 'cnuapp', 'CashNetUSA Main App', 'CNUAPP for CNU' ],
     [ 'test', 'Test Application', 'For testing' ],
    ].each do | r |
      Application.
        create!(:code => r[0], 
                :name => r[1], 
                :description => r[2] || '')
    end
  end

  def self.down
    drop_table :applications
  end
end
