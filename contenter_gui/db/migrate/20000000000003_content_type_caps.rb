# Additional content_type-based capabilities
class ContentTypeCaps < ActiveRecord::Migration
  def self.up
    if RAILS_ENV != 'development' || ENV['FORCE_MIGRATION']
      Contenter::Seeder.new.action!(:core_roles!)
    end
  end

  def self.down
    raise "NOT REVERTABLE"
  end
end
