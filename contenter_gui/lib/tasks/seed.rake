namespace :db do
  namespace :seed do
    desc 'Dump a database to yaml fixtures.  Set environment variables DB
      and DEST to specify the target database and destination path for the
      fixtures.  DB defaults to development and DEST defaults to RAILS_ROOT/
      db/seed.'
    task :dump => :environment do |t, args|
      args.with_defaults( :path => "#{RAILS_ROOT}/db/seed", :env => 'development' )
      ActiveRecord::Base.establish_connection(args.env)
      sql  = 'SELECT * FROM %s'
      
      # MySql
      # get_tables = 'show tables'
      # Postgres
      get_tables = <<-end_sql
        SELECT c.relname
        FROM pg_class c
        LEFT JOIN pg_roles r     ON r.oid = c.relowner
        LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind IN ('r','')
        AND n.nspname IN ('myappschema', 'public')
        AND pg_table_is_visible(c.oid)
      end_sql
    
      ActiveRecord::Base.connection.select_values(get_tables).each do |table_name|
        i = '000'
        File.open("#{path}/#{table_name}.yml", 'wb') do |file|
          file.write ActiveRecord::Base.connection.select_all(sql %
                                                              table_name).inject({}) { |hash, record|
            hash["#{table_name}_#{i.succ!}"] = record
            hash
          }.to_yaml
        end
      end
    end

    desc "Load seed fixtures (from db/seed) into the current environment's database."
    task :load => :environment do |t, args|
      ENV['env'] ||= 'test'
      $stderr.puts args.to_s # "loading seeds into #{ENV['env']}"

      ActiveRecord::Base.establish_connection(ENV['env'])
      require 'active_record/fixtures'
      Dir.glob(RAILS_ROOT + '/db/seed/*.yml').each do |file|
        Fixtures.create_fixtures('db/seed', File.basename(file, '.*'))
      end
    end

  end # namespace :seed
end # namespace :db
