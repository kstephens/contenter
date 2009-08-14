require 'seeder'

$seed_env = ENV['RAILS_ENV'] || RAILS_ENV

task 'db:test:clone_structure' => [ 'db:seed:test_env' ]

namespace :db do
  namespace :seed do
    task :test_env do
      $seed_env = 'test'
    end

    desc "Load seed data into the current environment's database."
    task :load => [:environment, :enable_introspection] do
      $stderr.puts "loading seeds into #{$seed_env}"

      ActiveRecord::Base.establish_connection($seed_env)

      Seeder.new.create_all
    end

  end # namespace :seed
end # namespace :db
