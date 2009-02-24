# These are all hack to prevent rake test from clobbering 
# seed data created in migrations.
#

class Rake::Task
  # http://blog.jayfields.com/2008/02/rake-task-overwriting.html
  def overwrite(&block)
    @actions.clear
    prerequisites.clear
    enhance(&block)
  end
  def abandon
    prerequisites.clear
    @actions.clear
  end
end

namespace :db do
  namespace :test do
    Rake::Task['db:test:purge'].abandon
    task :purge do
      $stderr.puts "db:test:purge: NOPE, NOT GONNA DO IT"
    end

    Rake::Task['db:test:prepare'].abandon
    task :prepare do
      $stderr.puts "db:test:prepare: NOPE, NOT GONNA DO IT"
    end
    
    Rake::Task['db:test:load'].abandon
    task :load do
      $stderr.puts "db:test:load: NOPE, NOT GONNA DO IT"
    end

    Rake::Task['db:test:clone_structure'].abandon
    task :load do
      $stderr.puts "db:test:clone_structure: NOPE, NOT GONNA DO IT"
    end

  end

  namespace :schema do
    Rake::Task['db:schema:load'].abandon
    task :load do
      $stderr.puts "db:schema:load: NOPE, NOT GONNA DO IT"
    end
  end
end

