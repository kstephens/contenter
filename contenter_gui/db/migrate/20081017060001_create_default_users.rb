class CreateDefaultUsers < ActiveRecord::Migration
  @@users = [ 'root', '__default__' ]
  def self.up
    @@users.each do | name |
      password = name + name
      user = User.create!(:login => name,
                          :name => name,
                          :email => "admin+#{name.gsub('_', '-')}@localhost.com",
                          :password => password,
                          :password_confirmation => password
                          )
      
      $stderr.puts "  The #{user.login.inspect} password is #{password.inspect}."
    end
  end

  def self.down
    @@users.each do | name |
      User.find(:first, :conditions => { :login => name }).destroy
    end
  end
end
