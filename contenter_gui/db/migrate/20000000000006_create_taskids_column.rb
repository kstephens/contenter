# A migration to add task_ids, a space delimited column of integers
# to contents and content_versions tables. 
# These columns are using empty string in place of null values
# to simplify the consumers of those columns values
class CreateTaskidsColumn < ActiveRecord::Migration
  def self.up
    if RAILS_ENV != 'development' || ENV['FORCE_MIGRATION']
      add_column :contents, :tasks, :string,
      :limit => 100,
      :null => false,
      :default => ""
      
      add_column :content_versions, :tasks, :string,
      :limit => 100,
      :null => false,
      :default => ""

      add_column :version_lists, :tasks, :string,
      :limit => 100,
      :null => false,
      :default => ""
    end
  end
  
  def self.down
    raise "NOT REVERTABLE"
  end
end
