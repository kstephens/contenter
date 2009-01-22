class CreateDefaultUsers < ActiveRecord::Migration
  def self.up
    password = "%06d" % rand(10000)
    User.create!(:login => 'root',
                 :name => 'root',
                 :email => 'root@localhost.com',
                 :password => password,
                 :password_confirmation => password
                 )

    $stderr.puts "The root password is #{password}, change it!"
  end

  def self.down
    User.find(:first, :login => 'root').destroy
  end
end
