# Add Content#filename.
class ContentFilenameMigration < ActiveRecord::Migration
  def self.up
    if RAILS_ENV != 'development' || ENV['FORCE_MIGRATION']
      [ :contents, :content_versions ].each do | t |
        add_column t, :filename, :string, :limit => 255, :null => false, :default => ''
      end
    end
  end

  def self.down
    raise "NOT REVERTABLE"
  end
end
