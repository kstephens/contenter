class CreateMimeTypes < ActiveRecord::Migration
  def self.up
    create_table :mime_types do | t |
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

    add_index :mime_types,
      :code, 
      :unique => true

    [
     [ '_',            'Any',          'Wildcard Mime Type' ],
     [ 'text/plain',   'text/plain',   'Plain Ascii Text' ],
     [ 'text/html',    'text/html',    'HTML Text' ],
    ].each do | r |
      MimeType.create!(:code => r[0], 
                       :name => r[1],
                       :description => r[2] || ''
                       )
    end
  end

  def self.down
    drop_table :mime_types
  end
end

