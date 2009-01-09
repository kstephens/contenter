class CreateContentTypes < ActiveRecord::Migration
  def self.up
    create_table :content_types do |t|
      t.column :lock_version, :integer,
        :null => false
      t.column :code, :string,
        :null => false
      t.column :name, :string,
        :null => false
      t.column :description, :string,
        :null => false
      t.column :key_regexp, :string,
        :null => false
      t.timestamps
    end

    add_index :content_types,
      :code, 
      :unique => true

    [
     [ 'phrase',   'phrase',   'Localized short phrases' ],
     [ 'email',    'email',    'Localized email templates' ],
     [ 'faq',      'faq',      'Localized frequently asked questions' ],
     [ 'contract', 'contract', 'Localized contract template', /\A[a-z0-9_]+(\/[a-z0-9_]+)*\Z/i ],
     [ 'image',    'image',    'Graphic image' ],
     [ 'sound',    'sound',    'Sound' ],
    ].each do | r |
      ContentType.create!(:code => r[0], 
                          :name => r[1],
                          :description => r[2] || '',
                          :key_regexp => (r[3] || /\A.+\Z/).inspect
                          )
    end
  end

  def self.down
    drop_table :content_types
  end
end
