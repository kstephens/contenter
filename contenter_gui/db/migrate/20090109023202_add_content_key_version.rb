class AddContentKeyVersion < ActiveRecord::Migration
  def self.up
    # Don't keep version 0!
    ActiveRecord::Base.connection.execute "UPDATE #{ContentKey.table_name} SET version = version + 1 WHERE version = 0"

    $stderr.puts "Creating ContentKey::Version records."
    ContentKey.find(:all).each do | o |
      if versions.size == 0
        $stderr.write "."; $stderr.flush
      else
        $stderr.write "+"; $stderr.flush
        o.instance_variable_set(:'@saving_version', true)
        o.save_version
      end
    end
    $stderr.puts " DONE"

  end

  def self.down
  end
end
