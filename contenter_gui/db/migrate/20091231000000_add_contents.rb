class AddContents < ActiveRecord::Migration
  def self.up
    UserTracking.current_user = 'root'

    api = Content::API.new
    api.load_from_yaml_file(File.dirname(__FILE__) + '/content.yml')
    $stderr.puts api.result.to_yaml
    raise "Errors!" unless api.errors.empty?
  end

  def self.down
  end
end

