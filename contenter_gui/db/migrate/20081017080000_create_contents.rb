class CreateContents < ActiveRecord::Migration
  def self.up
    create_table :contents do |t|
      t.column :key, :string, 
        :null => false
      t.column :content_type_id, :integer, 
        :null => false
      t.column :language_id, :integer, 
        :null => false
      t.column :country_id, :integer, 
        :null => false
      t.column :brand_id, :integer, 
        :null => false
      t.column :application_id, :integer, 
        :null => false
      t.column :content, :text, 
        :null => false
      t.timestamps
    end

    add_index :contents,
    [ 
     :key,
     :content_type_id,
     :language_id,
     :country_id,
     :brand_id,
     :application_id,
    ],
    :name => :contents_u, 
    :unique => true

    Content.load_from_yaml!(
                            File.open(File.dirname(__FILE__) + '/content.yml'){|fh| fh.read}
                            )
  end

  def self.down
    drop_table :contents
  end
end
