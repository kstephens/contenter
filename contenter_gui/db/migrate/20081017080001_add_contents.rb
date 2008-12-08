class AddContents < ActiveRecord::Migration
  def self.up
    data = File.open(File.dirname(__FILE__) + '/content.yml'){|fh| fh.read}
    Content.load_from_yaml!(data)
  end

  def self.down
  end
end

