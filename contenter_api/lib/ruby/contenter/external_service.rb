require 'contenter'

module Contenter
  # Class to manage connections to multiple external services.
  class ExternalService
    # A list of model classes to force establish_connection
    # during #for_each_database_connection.
    attr_accessor :model_classes

    attr_accessor :config_file

    # Defaults to "#{RAILS_ROOT}/config".
    attr_accessor :config_dir

    # Defaults to RAILS_ENV.
    attr_accessor :config_mode

    attr_accessor :allow_error

    attr_accessor :verbose

    def initialize opts = nil
      @verbose = false
      @allow_error = true

      opts ||= EMPTY_HASH
      opts.each do | k, v |
        send("#{k}=", v)
      end
    end


    def config
      @config ||=
        YAML::load(File.read(config_file))
    end

    def config_file
      @config_file ||= 
        (config_mode == :test ? [ "_#{config_mode}" ] : [ '_local', "_#{config_mode}", nil ]).
        map{|s| "#{config_dir}/external_service#{s}.yml"}.
        find{|f| File.exist?(f)} ||
        (raise Contenter::Error::Configuration, "#{self.class}: cannot file config_file")
      # $stderr.puts "config_file = #{@config_file.inspect}"; @config_file
    end

    def config_dir
      @config_dir ||=
        "#{RAILS_ROOT}/config"
    end

    def config_mode
      @config_mode ||=
        RAILS_ENV.to_sym
    end



    def service_value service_name, service_value, service
      service_name = service_name.to_sym
      service_value = service_value.to_sym
      cache = @service_value ||= { }
      cache = cache[service_name] ||= { }
      cache = cache[service_value] ||=
      cache = cache[service] ||=
        [
         begin
           x = config[:external_service][service_name] || 
             (raise Contenter::Error::Configuration, "#{config_file}: no [:external_service][#{service_name.inspect}]")
           v = nil
           v = _merge_val(v, (x[nil]           || EMPTY_HASH)[service])
           v = _merge_val(v, (x[service_value] || EMPTY_HASH)[service])
           v
         end
        ]
      
      cache.first
    end

    def service_hash service_name, service_value, service
      service_name = service_name.to_sym
      service_value = service_value.to_sym
      cache = @service_value ||= { }
      cache = cache[service_name] ||= { }
      cache = cache[service_value] ||= { }
      cache = cache[service] ||= 
        [
         begin
           x = config[:external_service][service_name] ||
             (raise Contenter::Error::Configuration, "#{config_file}: no [:external_service][#{service_name.inspect}]")
           $stderr.puts "   #{service_name.inspect} #{service_value.inspect} #{service.inspect}" if @verbose
           v = { }
           v = _merge_val(v, (x[nil]           || EMPTY_HASH)[nil])
           v = _merge_val(v, (x[nil]           || EMPTY_HASH)[service])
           v = _merge_val(v, (x[service_value] || EMPTY_HASH)[nil])
           v = _merge_val(v, (x[service_value] || EMPTY_HASH)[service])
           $stderr.puts "   v = #{v.inspect}" if @verbose
           v
         end
        ]
      cache.first
    end


    def _merge_val this, that
      case 
      when this.nil?
        that
      when that.nil?
        this
      when Hash === this 
        this.object_id != that.object_id && ! that.empty? ? this.merge(that) : this
      else
        that
      end
    end


    #########################################


    # Yields to a block for each database connection
    # established to a list of model classes.
    #
    def database_connection_map opts = nil
      opts ||= { }

      result = 
      database_connections(opts).map do | conn |
        conn = conn.dup # protect from mutations.
        conn[:error] = nil
        conn[:allow_error] &&= @allow_error
 
        connection = nil
        begin
          if conn[:test_mode]
            $stderr.puts "#{self.class.name}: test_mode #{conn.inspect}" if @verbose
          else
            (opts[:model_classes] || @model_classes || EMPTY_ARRAY).each do | cls |
              cls = eval(cls) if String === cls
              cls.establish_connection(conn)
              connection ||= cls.connection
              cls.reset_column_information
            end
          end
          
          # $stderr.puts "   for_each_database_connection conn = #{conn.inspect}"

          yield conn

        rescue Exception => err
          $stderr.puts "#{self.class.name}: ERROR #{err.inspect}\n#{err.backtrace * "\n"}"
          raise err unless conn[:allow_error]
          conn[:error] = err
        end
      end

      result
    end

    # service_name = :content_status
    # service_value = :released
    # database_name = :seo_db
    # database_cluster = :US
    def database_connections opts
      opts[:service_name] || (raise ArgumentError)
      opts[:service_value] || (raise ArgumentError)
      opts[:database_name] || (raise ArgumentError)
      opts[:database_cluster] || (raise ArgumentError)

      # Get a list of database environments for the service name/value.
      database_envs = service_value(opts[:service_name], opts[:service_value], opts[:database_name])
      database_envs = [ database_envs ] unless Array === database_envs
      database_envs = database_envs.uniq.compact
      $stderr.puts "  database_envs = #{database_envs.inspect}" if @verbose

      result = database_envs.map do | db_env |
        $stderr.puts "   db_env = #{db_env.inspect}" if @verbose
        database_options(opts[:database_name], db_env, opts[:database_cluster])
      end.compact.uniq

      $stderr.puts "database_connections #{opts.inspect} =>\n#{result.pretty_inspect}" if @verbose

      result
    end


    def database_options service_name, service_value, service
      hash = service_hash service_name, service_value, service
      $stderr.puts "hash = #{hash.inspect}" if @verbose
      hash = nil if hash && ! ( hash[:username] && hash[:password] && hash[:host] )
      hash
    end

  end
end
