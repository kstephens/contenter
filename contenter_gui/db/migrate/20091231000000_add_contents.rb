class AddContents < ActiveRecord::Migration
  def self.up
    Content::API.
      new.
      load_from_yaml_file(File.dirname(__FILE__) + '/content.yml')
  end

  def self.down
  end
end

