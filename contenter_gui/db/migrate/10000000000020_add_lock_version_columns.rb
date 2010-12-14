# An idempotent migration to add lock_version columns to the *_versions tables created by
# acts_as_versioned plugin.
class AddLockVersionColumns < ActiveRecord::Migration

  LOCK_COLUMN = :lock_version

  def self.up
    [ Content::Version, ContentKey::Version ].each do | cls |
      table = cls.table_name

      # acts_as_versioned will sometimes insert  NULL in the version tables for the lockversion column !!
      ensure_column table, LOCK_COLUMN, :integer, :null => cls.name.include?('Version'), :default => 0

      # until the hack to allow null in *::Version tables goes away...
      # execute("update #{table} set lock_version = 0 where lock_version IS NULL")
    end
   end

  def self.down
    [ Content::Version, ContentKey::Version ].each do | cls |
      table = cls.table_name
      remove_column table, LOCK_COLUMN
    end
  end

  # Alternative to add_column that will do nothing if a column by that name exists already
  # Ensures a column of the name will exist - either creating it or leaving the existing one be
  # Looks up the table_name in AR::Base's descendants to query them whether this column exists (by name) yet
  # Currently does not ensure that the options for the column are the same, nor ensure all models are loaded
  def self.ensure_column tn, cn, *opts
    klass = begin
      @@tables_to_classes ||= 
        ActiveRecord::Base.class_eval{ subclasses }.inject({}) do |map, this_class|
          map[this_class.table_name] = this_class
          map
        end
      @@tables_to_classes[tn]
    rescue 
      nil
    end

    # only add if it still needs addin
    if klass.nil? || ! klass.columns.map(&:name).include?(cn.to_s)
      add_column tn, cn, *opts
    end
  end

end
