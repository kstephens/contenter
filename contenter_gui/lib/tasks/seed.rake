require 'contenter/seeder'

$seed_env = ENV['RAILS_ENV'] || RAILS_ENV

task 'db:test:clone_structure' => [ 'db:seed:test_env' ]

namespace :db do
  namespace :seed do
    task :test_env do
      $seed_env = 'test'
    end

    desc "Load seed data into the current environment's database."
    task :load => [:environment ] do
      $stderr.puts "Loading seed data into #{$seed_env}.."

      ActiveRecord::Base.establish_connection($seed_env)

      Contenter::Seeder.new.all!
    end

  end # namespace :seed
end # namespace :db
