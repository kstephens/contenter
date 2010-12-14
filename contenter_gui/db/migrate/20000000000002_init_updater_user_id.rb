# Make all FKC's DEFERRABLE.
class InitUpdaterUserId < ActiveRecord::Migration
  def self.up
    if RAILS_ENV != 'development' || ENV['FORCE_MIGRATION']
      conn = ActiveRecord::Base.connection
      conn.tables.each do | table |
        cols = conn.columns(table).inject({ }){ | h, c | h[c.name] = c; h }
        if cols["updater_user_id"] && cols["creator_user_id"]
          execute("UPDATE #{table} SET updater_user_id = creator_user_id WHERE updater_user_id IS NULL")
          execute("ALTER TABLE #{table} ALTER COLUMN updater_user_id SET NOT NULL")
        end
      end
    end
  end

  def self.down
    raise "NOT REVERTABLE"
  end
end
