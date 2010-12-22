module RedHillConsulting::ForeignKeyMigrations::ActiveRecord
  module Migration
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      @@foreign_key_defaults = { }
      def foreign_key_defaults 
        @@foreign_key_defaults
      end
      def foreign_key_defaults= hash
        @@foreign_key_defaults = hash
      end
      def add_column(table_name, column_name, type, options = {})
        super
        references = ActiveRecord::Base.references(table_name, column_name, options)
        options = foreign_key_defaults.merge(options)
        add_foreign_key(table_name, column_name, references.first, references.last, options) if references
      end
    end
  end
end
