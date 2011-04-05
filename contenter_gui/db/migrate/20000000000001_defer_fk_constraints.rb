# Make all FKC's DEFERRABLE.
class DeferFkConstraints < ActiveRecord::Migration
  def self.up
    return unless RAILS_ENV != 'development' # || ENV['FORCE_MIGRATION']
    execute("UPDATE pg_constraint SET condeferrable = 't' WHERE conname LIKE '%_fkey' AND contype = 'f' AND connamespace NOT IN (SELECT oid FROM pg_namespace WHERE nspname LIKE 'pg_%' OR nspname IN ('londiste', 'pgq'));")
  end

  def self.down
    raise "NOT REVERTABLE"
  end
end
