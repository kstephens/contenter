require 'contenter/error'

require 'digest/md5'


class Content
# Handles bulk dump and load.
class API
  # Stats of processing.
  attr_reader :stats

  # Options given to constructor.
  attr_accessor :opts

  # Stream to log load_from_yaml progress.
  attr_accessor :log

  # Array of all errors.
  attr_reader :errors

  # The Hash describing the results of the load_from_yaml progress.
  attr_reader :result

  # Comment for the VersionList.
  attr_accessor :comment

  # The result api version.
  attr_accessor :api_version

  # The format of the result.
  attr_accessor :format

  # If true allow all errors to be trapped while
  # continuing to process other rows.
  attr_accessor :allow_multiple_errors

  # If true, returns statistics in yaml result.
  attr_accessor :include_stats

  # The VersionList object created during the bulk changes.
  attr_reader :version_list

  # Parameters for dump.
  attr_accessor :params

  # Log4R object.
  attr_accessor :logger

  attr_accessor :objects


  def initialize opts = { }
    @api_version = 1
    @log = nil
    @stats = {
      :found => 0,
      :updated => 0,
      :created => 0,
      :ignored => 0,
      :errors => 0,
      :version_conflicts => 0,
      :md5sum_mismatches => 0,
      :data_encoding => 0,
      :data_decoding => 0,
    }
    @errors = [ ]
    @result = { }
    @include_stats = true
    @allow_multiple_errors = true
    @allow_multiple_errors = false
    @comment = nil
    @logger = nil
    @format = nil

    @opts = opts
    opts.each do | k, v |
      s = "#{k}="
      send(s, v) if respond_to? s
    end
  end


  def comment
    @result[:comment] || @comment
  end


  def logger
    @logger ||=
      Rails.logger
  end


  def log_write msg = nil
    if @log
      msg ||= yield if block_given?
      return if msg.nil?
      @log.write msg.to_s
      @log.flush
    end
  end


  def log_puts msg = nil
    if @log
      msg ||= yield if block_given?
      return if msg.nil?
      @log.puts msg.to_s
      @log.flush
    end
  end


  # Returns a Hash representing the result to passed back 
  # through the ApiController as YAML
  def result
    unless @result[:api_version] 
      @result[:api_version] = @api_version
      @result[:stats] = @stats if self.include_stats
    end
    if @stats[:errors] > 0
      @result[:errors] = @errors.map { | x | [ x[0], x[1].inspect, x[1].backtrace * "\n" ] }
    end
    @result
  end


  def log_error data, err
    if ! @errors.find { | x | x[1] == err }
      logger.error "#{err.inspect}\n  #{err.backtrace * "\n  "}"
      @stats[:errors] += 1
      @errors << [ data, err, @row_id ]
    end
  end


  def trap_errors data = nil
    yield
    self
  rescue Exception => err
    log_error data, err
    self
  end


  ####################################################################
  # Bulk Format
  #

  def dump params = nil, opts = { }
    params ||= self.params

    @result[:action] = :dump
    params[:sort] ||= '1'

    # Get the columns requested.
    want_columns = (params[:columns] || '').split(',').map{|x| x.to_sym}

    # $stderr.puts "  params[:id] = #{params[:id].inspect}"

    # Get format from params.
    @format = params.delete(:format) if params[:format]
    @format ||= :yaml

    # Get matching Content objects.
    opts[:latest] = _param_to_bool(params.delete(:latest))
    opts[:versions] = _param_to_bool(params.delete(:versions))
    opts[:params] = params
    # $stderr.puts "  opts = #{opts.inspect}"
    result = Content::Query.new(opts).find(:all)

    columns = Content.display_column_names.dup

    # Limit to requested columns.
    if want_columns.empty?
      # Remove id, if not specified.
      columns = columns - [ :id ]
    else
      columns = want_columns.select { | x | columns.include?(x) } 
    end
    columns += [ :data_encoding ] if columns.include?(:data)

    # Sort them.
    if _param_to_bool(params[:sort])
      # @stats[:cmps] = 0
      result.sort! do | a, b |
        # @stats[:cmps] += 1
        a.sort_array <=> b.sort_array
      end
    end

    search_count = result.size

    # $stderr.puts "  result = #{result.inspect}"

    # Make them unique.
    if _param_to_bool(params[:unique])
      # Map results to basic values.
      result.map! do | x |
        x = x.to_hash
        columns.map do | c |
          x[c]
        end
      end
      result.uniq!
    end

    # Found stats.
    @stats[:found] = search_count

    @result.update({
                     :search_count => search_count,
                     :contents_columns => columns,
                     :contents => result,
                     # :params => self.params,
                   })

    # Render result as YAML.
    # Use self.result here to insure errors and stats are added.
    result = Contenter::Bulk.new(:document => self.result, :format => @format).render
    result = result.string unless String === result
    result

  rescue Exception => error
    $stderr.puts "#{self.class.name}: ERROR: #{error.inspect}"
    @result[:contents] = [ ]
    @result[:format] = @format
    log_error params, error

    # Render result as YAML.
    result = Contenter::Bulk.new(:document => self.result, :format => :yaml).render.string
  end


  def _param_to_bool x
    ! (x == nil || x.to_s == '0' || x.to_s == '')
  end
  private :_param_to_bool



  ####################################################################
  # Bulk Load
  #


  def load_from_stream stream
    trap_errors do
      hash = YAML::load(stream)
      load_from_hash hash
    end
  end


  def load_from_yaml_file yaml_file
    trap_errors do
      hash = YAML::load_file(yaml_file)
      load_from_hash hash
    end
  end


  def load_from_yaml yaml
    trap_errors do
      hash = YAML::load(yaml)
      load_from_hash hash
    end
  end


  def load_from_hash result
    load_begin do 
      unless av = result[:api_version]
        raise Contenter::Error::InvalidInput, "api_version not specified" 
      end
      av = av.to_i
      if av > api_version
        raise Contenter::Error::InvalidInput, "api_version #{av} incompatible" 
      end
      
      columns = result[:contents_columns] || (raise Contenter::Error::InvalidInput, "contents_columns not specified")
      
      hashes = 
        (result[:contents] || 
         (raise Contenter::Error::InvalidInput, "contents not specified")).map do | r |
        Hash[*columns.zip(r.map{|x| x.to_s_const}).flatten]
      end
      
      log_puts do
        "Processing: #{hashes.size} records"
      end

      hashes.each do | hash |
        load_content_from_hash hash
      end
    end
  end


  def load_from_hash_array hashes
    load_begin do
      log_puts do
        "Processing: #{hashes.size} records"
      end
      hashes.each do | hash |
        load_content_from_hash hash
      end
    end
  end
  

  def load_begin
    t0 = Time.now.to_f
    new_cache = nil

    @result[:action] = :load

    @row_id = -1

    ModelCache.with_current do | cache |
      new_cache = cache
      Content.transaction do 
        yield
      end
    end
    log_puts :DONE
    
    unless @errors.empty?
      raise Contenter::Error, "Errors occurred"
    end
    
    self
  ensure
    @stats[:elasped_time] = Time.now.to_f - t0
    @stats[:cache] = new_cache && new_cache.stats
  end


  PRIMARY_KEYS = [ :uuid ].freeze

  # Loads a single Hash.
  def load_content_from_hash hash, row_id = nil
    row_id ||= (@row_id += 1)

    log_puts do 
      ct = hash[:content_type]
      if @ct != ct
        @ct = ct
        "\n#{ct}:"
      else
        nil
      end
    end
    log_write do
      (row_id % 100 == 0) ? row_id : nil
    end

    hash = hash.dup

    # Do not bother with these fields.
    hash.delete(:updater)
    hash.delete(:creator)
    hash.delete(:content_status)

    # Handle encoding.
    if Contenter::Api::Parse.decode_hash! hash
      @stats[:data_decoding] += 1
    end

    hash_normalized = false
    
    obj = nil
    
    # Try to locate by uuid first.
    PRIMARY_KEYS.each do | key |
      obj = (x = hash[key]) && (! x.empty?) && Content.find(:first, :conditions => { key => x })
      break if obj
    end

    # Try to locate by all other params.
    unless obj 
      # hash = Content.normalize_hash(hash) unless hash_normalized
      # hash_normalized = true
      # hash[:content_type] ||= hash[:content_key].content_type
      content_type = ContentType[hash[:content_type]]
      if content_type
        content_key = content_type.content_keys.by_code(hash[:content_key])
        if content_key
          conditions = { :content_key_id => content_key.id }
          conditions[:language_id]    = Language[hash[:language] || :_]
          conditions[:country_id]     = Country[hash[:country] || :_]
          conditions[:brand_id]       = Brand[hash[:brand] || :_]
          conditions[:application_id] = Application[hash[:application] || :_]
          conditions[:mime_type_id]   = MimeType[hash[:mime_type] || :_]
          obj = Content.find(:all, :conditions => conditions, :limit => 2)
          if obj.size > 1 
            raise Contenter::Error::Ambiguous, "Search by #{params.inspect} is ambiguous, found matching object with ids #{obj.map{|x| x.id}.inspect}"
          end
          obj = obj.first
        end
      end
    end

    action = nil

    if obj  
      hash = Content.normalize_hash(hash) unless hash_normalized
      hash_normalized = true

      # Do not compare by uuid or id.
      cmp_hash = hash.dup
      cmp_hash.delete(:uuid) if cmp_hash[:uuid].blank?
      cmp_hash.delete(:id)
 
      # $stderr.puts "  UPDATE: load_from_hash(#{hash.inspect})"
      if obj.is_equal_to_hash? cmp_hash
        @stats[:ignored] += 1
        log_write :'.'
      else
        # Check for version conflict.
        if ! hash[:version].blank? && 
            hash[:version].to_s != obj.version.to_s
          @stats[:version_conflicts] += 1
          log_write :'V'
          raise Contenter::Error::VersionConflict, "Content uuid #{obj.uuid}: edit of version #{hash[:version]} of which is now version #{obj.version}"
        end

        # If given md5sum is different the md5sum of data,
        # assume that the file was edited by a human.
        if hash[:md5sum] && hash[:md5sum] != Digest::MD5.new.hexdigest(hash[:data])
          @stats[:md5sum_mismatches] += 1
          log_write :'#'
        end

        if opts[:error_on_update]
          log_puts { "\n  row=#{row_id} id=#{obj.id} uuid=#{obj.uuid} #{obj.to_hash.inspect}" }
          log_puts { "\n  hash = #{hash.inspect}" }
          log_puts { "\n  diff = #{obj.diff_to_hash(hash).inspect}" }
          raise "STOP"
        end

        # Set attributes.
        hash.keys.to_a.each do | k |
          hash.delete(k) if Content::CHANGE_COLUMNS.include?(k)
        end
        obj.attributes = hash

        # Check if object is altered.
        if obj.content_changed?
          log_write :'*'
          obj.save!
          @stats[:updated] += 1
          action = :save
        else
          @stats[:ignored] += 1
          log_write :'-'
        end
      end
    else
      # $stderr.puts "   CREATE: hash = #{hash.inspect}"
      hash = Content.normalize_hash(hash) unless hash_normalized
      hash_normalized = true
      # $stderr.puts "  CREATE: load_from_hash(#{hash.inspect})"
      log_write :'+'
      obj = Content.create!(hash)
      @stats[:created] += 1
      action = :create
    end

    obj
   
    rescue Exception => err
      log_write :E
      log_error hash, err
      raise err unless @allow_multiple_errors
    end
    
  end # class

  def inspect
    to_s
  end

end # module 


class Symbol
  # Returns a frozen String via to_s.
  def to_s_const
    @to_s_const ||=
      to_s.freeze
  end
end


class Object
  # Returns a non-frozen self.
  def to_s_const
    self
  end
end


