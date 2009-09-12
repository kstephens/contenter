class AddContentVersionIndex < ActiveRecord::Migration
  def self.up
    [ Content.table_name, Content::Version.table_name ].each do | tn |
      ([ :uuid, :md5sum ] + Content::BELONGS_TO_ID).each do | col |
        next if col == :uuid and tn == Content.table_name
        add_index tn, col
      end
    end
  end

  def self.down
  end
end

