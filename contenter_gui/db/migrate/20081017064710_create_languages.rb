class CreateLanguages < ActiveRecord::Migration
  def self.up
    create_table :languages do |t|
      t.column :lock_version, :integer,
        :null => false
      t.column :code, :string,
        :null => false
      t.column :name, :string,
        :null => false
      t.column :description, :string,
        :null => false
      t.timestamps
    end

    add_index :languages,
      :code,
      :unique => true

    [
     [ '_', 'Any Language', 'Any Language' ],
     [ 'en', 'English' ],
     [ 'es', 'Spanish' ],
     [ 'fr', 'French' ],
    ].each do | r |
      Language.
        create!(:code => r[0],
                :name => r[1], 
                :description => r[2] || ''
                )
    end
  end

  def self.down
    drop_table :languages
  end
end
