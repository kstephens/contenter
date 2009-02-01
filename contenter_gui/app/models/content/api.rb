require 'digest/md5'


class Content
# Handles bulk dump and load.
class API
  attr_reader :stats

  attr_accessor :opts

  attr_accessor :log

  attr_reader :errors

  attr_reader :result

  attr_accessor :api_version

  attr_accessor :allow_multiple_errors

  def initialize opts = { }
    @api_version = 1
    @log = nil
    @stats = {
      :found => 0,
      :updated => 0,
      :created => 0,
      :ignored => 0,
      :errors => 0,
    }
    @errors = [ ]
    @result = { }
    @allow_multiple_errors = true
    @allow_multiple_errors = false

    @opts = opts
    opts.each do | k, v |
      s = "#{k}="
      send(s, v) if respond_to? s
    end
  end


  def log_write msg = nil
    if @log
      msg ||= yield if block_given?
      @log.write msg.to_s
      @log.flush
    end
  end


  def log_puts msg = nil
    if @log
      msg ||= yield if block_given?
      @log.puts msg.to_s
      @log.flush
    end
  end


  # Returns a Hash representing the result to passed back 
  # through the ApiController as YAML
  def result
    unless @result[:api_version] 
      @result[:api_version] = @api_version
      @result[:stats] = @stats
      @result[:errors] = @errors.map { | x | [ x[0], x[1].inspect, x[1].backtrace * "\n  " ] }
    end

    @result
  end


  def trap_errors data = nil
    yield
  rescue Exception => err
    if ! @errors.find { | x | x[1] == err }
      @stats[:errors] += 1
      @errors << [ data, err ]
    end
    self
  end


  ####################################################################
  # Bulk Format
  #

  def dump params = { }
    @result[:action] = :dump
    params[:sort] ||= '1'

    # Get the columns requested.
    want_columns = (params[:columns] || '').split(',').map{|x| x.to_sym}

    # Get matching Content objects.
    result = Content.find_by_params(:all, params)

    columns = Content.display_column_names.dup

    # Limit to requested columns.
    if want_columns.empty?
      # Remove id, if not specified.
      columns = columns - [ :id ]
    else
      columns = want_columns.select { | x | columns.include?(x) } 
    end

    # Sort them.
    if (params[:sort] || 0).to_s != '0'
      # @stats[:cmps] = 0
      result.sort! do | a, b |
        # @stats[:cmps] += 1
        a.sort_array <=> b.sort_array
      end
    end

    # Map results to basic values.
    result.map! do | x |
      x = x.to_hash
      columns.map do | c |
        x[c]
      end
    end
    search_count = result.size

    # $stderr.puts "  result = #{result.inspect}"

    # Make them unique.
    if (params[:unique] || 0).to_s != '0'
      result.uniq!
    end

    # Create result Hash.
    @stats[:found] = search_count

    @result.update({
                     :search_count => search_count,
                     :results_columns => columns,
                     :results => result,
                     # :params => self.params,
                   })

    # Render result as YAML.
    result = Contenter::Bulk.new(self.result).render_yaml.string

  rescue Exception => error
    @stats[:errors] += 1
    @errors << [ params, error ]

    # Render result as YAML.
    result = Contenter::Bulk.new(self.result).render_yaml.string

  end



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
    @result[:action] = :load

    unless av = result[:api_version]
      raise Contenter::Error::InvalidInput, "api_version not specified" 
    end
    av = av.to_i
    if av > api_version
      raise Contenter::Error::InvalidInput, "api_version #{av} incompatible" 
    end

    columns = result[:results_columns] || (raise Contenter::Error::InvalidInput, "results_columns not specified")

    row_i = -1
    @objects = 
    Content.transaction do 
      (result[:results] || (raise Contenter::Error::InvalidInput, "results not specified")).
      map do | r |
        hash = Hash[*columns.zip(r.map{|x| x.to_s_const}).flatten]
        load_content_from_hash hash, (row_i += 1)
      end
    end

    log_puts :DONE

    unless @errors.empty?
      raise Contenter::Error, "Errors occurred"
    end
    
    self
  end


  def load_content_from_hash hash, row_i = nil
    @result[:action] = :load

    hash = hash.dup
    hash_normalized = false
    
    obj = nil
    
    # Try to locate by uuid first.
    [ :uuid ].find do | key |
      obj = hash[key] && Content.find_by_params(:first, key => hash[key])
      break if obj
    end

    # Try to locate by all other params.
    unless obj 
      # hash = Content.normalize_hash(hash) unless hash_normalized
      # hash_normalized = true
      # hash[:content_type] ||= hash[:content_key].content_type
      params = hash.dup
      Content.default_hash!(params)
      params.delete(:id)
      params.delete(:data)
      params.delete(:md5sum)
      obj = Content.find_by_params(:all, params, :limit => 2, :exact => true)
      if obj.size > 1 
        # $stderr.puts "obj[0] = #{obj[0].to_hash.inspect}"
        # $stderr.puts "obj[1] = #{obj[1].to_hash.inspect}"
        raise Content::Error::Ambiguous, "Search by #{params.inspect} is ambiguous found matching object with ids #{obj.map{|x| x.id}.inspect}"
      end
      obj = obj.first
    end

    action = nil

    if obj  
      hash = Content.normalize_hash(hash) unless hash_normalized
      hash_normalized = true

      # $stderr.puts "  UPDATE: load_from_hash(#{hash.inspect})"
      if obj.is_equal_to_hash? hash
        @stats[:ignored] += 1
        log_write :'.'
      else
        # If given md5sum is different the md5sum of data,
        # assume that the file was edited by a human.
        # And avoid a version error.
        if hash[:md5sum] && hash[:md5sum] != Digest::MD5.new.hexdigest(hash[:data])
          log_write :'#'
          hash[:version] = obj.version.to_s
        end

        # Check version.
        if hash[:version] && hash[:version].to_s != obj.version.to_s
          raise Content::Error::Collision, "Content uuid #{obj.uuid}: edit of version #{hash[:version]} of which is now version #{obj.version}"
        end

        @stats[:updated] += 1
        log_write :'*'
        if opts[:error_on_update]
          log_puts { "\n  #{row_i} #{obj.to_hash.inspect}" }
          log_puts { "\n  diff = #{obj.diff_to_hash(hash).inspect}" }
          raise "STOP"
        end
        obj.attributes = hash
        obj.save!
        action = :save
      end
    else
      @stats[:created] += 1
      hash = Content.normalize_hash(hash)
      # $stderr.puts "  CREATE: load_from_hash(#{hash.inspect})"
      log_write :'+'
      obj = Content.create!(hash)
      action = :create
    end

    obj
      
    rescue Exception => err
      log_write :E
      @stats[:errors] += 1
      @errors << [ hash, err ]
      raise err unless @allow_multiple_errors
    end
    
  end

end


class Symbol
  def to_s_const
    @to_s_const ||=
      to_s.freeze
  end
end

class Object
  def to_s_const
    self
  end
end


