# Additional content_type support for mime_types.
class ContentTypeMimeType < ActiveRecord::Migration
  def self.up
    return unless RAILS_ENV != 'development' || ENV['FORCE_MIGRATION']
      [ :languages, 
        :countries, 
        :brands, 
        :applications, 
        :mime_types, 
        :content_types, 
        :version_lists,
        :version_list_names,
        :contents,
        :content_versions,
      ].each do | t |
        add_column t, :aux_data, :text, :null => false, :default => "--- {}\n\n"
        eval(t.to_s.singularize.classify).reset_column_information
      end

      [
       :content_keys,
       :content_key_versions,
      ].each do | t |
        rename_column t, :data, :aux_data
        eval(t.to_s.singularize.classify).reset_column_information
      end

      ################################################################

      t = :mime_types

      add_column t, :mime_type_super_id, :integer, :null => true, :references => :mime_types

      MimeType.reset_column_information
      
      Contenter::Seeder.new.action!(:core_mime_types!)
      
      ################################################################

      t = :content_types

      add_column t, :mime_type_id, :integer, :null => false, :default => MimeType[:_].id

      ContentType.reset_column_information

      Contenter::Seeder.new.action!(:core_content_types!)
  end

  def self.down
    raise "NOT REVERTABLE"
  end
end
