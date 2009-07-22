class AddContents < ActiveRecord::Migration
  @@rln = [
           :production,
           :development,
           :integration,
          ]

  def self.up
    UserTracking.current_user = 'root'

    api = Content::API.new(:log => $stderr)
=begin
    api.load_from_yaml_file(File.dirname(__FILE__) + '/content.yml')
    $stderr.puts api.result.to_yaml
    raise "Errors!" unless api.errors.empty?
=end

    # Create some VLNs.
    @@rln.each do | n |
      VersionListName.create!(:name => n.to_s, :description => '', :version_list => api.version_list)
    end
  end

  def self.down
    @@rln.each do | n | 
      VersionListName.find(:first, :conditions => { :name => n.to_s } ).destroy
    end
  end
end

