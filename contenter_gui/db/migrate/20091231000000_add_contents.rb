class AddContents < ActiveRecord::Migration
  @@rln = [
           :production,
           :development,
           :integration,
          ]

  def self.up
    UserTracking.current_user = 'root'

=begin
    api = Content::API.new(:log => $stderr)
    api.load_from_yaml_file(File.dirname(__FILE__) + '/content.yml')
    $stderr.puts api.result.to_yaml
    raise "Errors!" unless api.errors.empty?
=end

    # Create some RLNs.
    @@rln.each do | n |
      RevisionListName.create!(:name => n.to_s, :description => '', :revision_list => api.revision_list)
    end
  end

  def self.down
    @@rln.each do | n | 
      RevisionListName.find(:first, :conditions => { :name => n.to_s } ).destroy
    end
  end
end

