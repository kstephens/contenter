
$seed_env = ENV['RAILS_ENV'] || RAILS_ENV

task 'db:test:clone_structure' => [ 'db:seed:test_env' ]

task :environment => :disable_streamlined

task :disable_streamlined do
  ENV['FUCK_YOU_STREAMLINED'] = '1'
end

namespace :db do
  namespace :seed do
    task :test_env do
      $seed_env = 'test'
    end

    desc "Load seed data into the current environment's database."
    task :load => [ :environment ] do
      require 'aunt/seeder'
      require 'contenter/seeder'

      $stderr.puts "Loading seed data into #{$seed_env}.."

      ActiveRecord::Base.establish_connection($seed_env)

      Aunt::Seeder.new.all!
      Contenter::Seeder.new.all!
    end

  end # namespace :seed
end # namespace :db
