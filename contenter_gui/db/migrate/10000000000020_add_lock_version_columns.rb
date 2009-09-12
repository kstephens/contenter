# An idempotent migration.
# 
class AddLockVersionColumns < ActiveRecord::Migration

  LOCK_COLUMN = :lock_version

  def self.up
    [ Content, ContentKey, Content::Version, ContentKey::Version ].each do | cls |
      table = cls.table_name
      unless cls.columns.map(&:name).include? LOCK_COLUMN.to_s
        # allow nulls in the version table where we wont be updating, but not in the main tables
        add_column table, LOCK_COLUMN, :integer, :null => cls.name.include?('Version'), :default => 0
      end
    end
   end

  def self.down
    [ Content, ContentKey, Content::Version, ContentKey::Version ].each do | cls |
      table = cls.table_name
      remove_column table, LOCK_COLUMN
    end
  end
end
