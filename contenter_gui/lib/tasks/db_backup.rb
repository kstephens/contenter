
namespace :db do
  namespace :backup do
    def backup_directory dir = nil
      @@backup_directory ||= 
        (
         dir ||
         ENV['db_backup_directory'] ||
         'db/backup'
         ).dup.freeze
    end
    def backup_file file = nil
      @@backup_file ||=
        (
         file || 
         ENV['db_backup_file'] || 
         "#{backup_directory}/:database:-#{RAILS_ENV}-#{Time.now.strftime('%Y%m%d%H%M%S')}.sql"
         ).dup.freeze
    end

    desc "Backup database to #{backup_file}"
    task :backup => [ :environment ] do
      file = nil
      db_command do | c |
        file = backup_file.gsub(':database:', c[:database])
        file << '.gz'
        mkdir_p File.dirname(file)
        ":password: pg_dump :host: :port: :username: -b :database: | gzip -9 > #{file}"
      end
      verbose(false) do
        sh "/bin/ls -l #{file.inspect}"
      end
    end

    desc "Restore database to backup_file=; ***WARNING***: WILL CLOBBER YOUR CURRENT DATABASE!"
    task :restore => [ :environment, 'db:drop', 'db:create' ] do
      file = ENV['backup_file'] || raise(ArgumentError, "backup_file= not specfied")
      db_command do | c |
        cmd = "ruby -npe 'if (m = /^(\s*ALTER .*? OWNER TO\s+)([^\s;]+)(.*)$/.match($_)) && m[2] != \"postgres\"; $_ = m[1] + #{c[:username].inspect} + m[3]; end' | :password: psql :host: :port: :username: :database:"
        if file =~ /\.gz\Z/
          cmd = "gunzip < #{file} | #{cmd}"
        else
          cmd = "cat #{file} | #{cmd}"
        end
        cmd
      end
    end

    task :db_drop_no_error do
      begin
        Task[':db:drop'].execute
      rescue Exception => err
        $stderr.puts "db_drop_no_error: #{err.inspect}"
      end
    end

    desc "Cull up old backups"
    task :cull => [ :environment ] do
      backups = Dir["#{backup_directory}/*.sql*"].sort
      now = Time.now
      to_delete = backups.select { | f | File.mtime(f) < now - 28.days }
      puts "Deleting #{to_delete.inspect}" unless to_delete.empty?
      to_delete.each { | f | File.unlink(f) }
    end

    def db_command cmd = nil
      env = ENV['env'] || RAILS_ENV
      config = ActiveRecord::Base.configurations[env]
      # require 'pp'; pp [ env, config ]

      # Set up options
      c = config.dup.symbolize_keys

      if block_given?
        cmd = yield(c)
      end
      raise(ArgumentError, "cmd not specified") if cmd.blank?

      # Prepare for expansion in cmd.
      c[:host] &&= "-h #{c[:host].inspect}"
      c[:port] &&= "-p #{c[:port]}"
      c[:username] &&= "-U #{c[:username].inspect}"
 
      cmd = cmd.dup
      cmd.gsub!(':username:', c[:username] || '')
      cmd.gsub!(':port:', c[:port] || '') 
      cmd.gsub!(':host:', c[:host] || '')
      cmd.gsub!(':database:', c[:database].inspect)

      verbose(false) do
        puts "#{cmd.gsub(/\s*:password:\s*/, '')}"
        cmd.sub!(':password:', "PGPASSWORD=#{c[:password].inspect} ")
        sh cmd
      end

    end

  end # namespace :backup
end # namespace :db
