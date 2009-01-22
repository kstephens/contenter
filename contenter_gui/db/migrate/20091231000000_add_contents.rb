class AddContents < ActiveRecord::Migration
  def self.up
    UserTracking.current_user = 'root'

    Content::API.
      new.
      load_from_yaml_file(File.dirname(__FILE__) + '/content.yml')
  end

  def self.down
  end
end

