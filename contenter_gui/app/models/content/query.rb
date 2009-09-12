

class Content
#
# Searches Content and Content::Version
#
class Query
  # The class to query against: Content or Content::Version
  attr_accessor :model_class

  # The query parameters.
  attr_reader :params

  # The query options.
  #   :limit
  #   :exact
  #   :like
  attr_reader :options
  
  # A subquery.
  # Can be a Hash or a Content::Query object.
  attr_accessor :subquery

  # A user query string.
  # Generates params.
  attr_accessor :user_query

  # Finds latests Content::Version that matches the query criteria.
  attr_accessor :latest

  # Finds all Content::Version records that match the search criteria.
  attr_accessor :versions


  def initialize options = EMPTY_HASH
    @model_class = Content
    @params = { }
    @subquery = nil
    self.options = options
  end


  def options= options
    @options = options
    options.each do | k, v |
      s = "#{k}="
      send(s, v) if respond_to? s
    end
  end


  def params= params
    params &&= params.inject({ }) {| h, (k, v) | h[k.to_sym] = v; h }
    @params.update(params || { })
  end


  def subquery= x
    x = self.class.new(x) if Hash === x
    @subquery = x
  end


  def user_query= q
    q ||= ''
    q = q.dup
    q.gsub!(/\A\s+|\s+\Z/, '')

    return if q.blank?
    
    @user_query = q

    search_options = {
    }

    subquery = nil
    (Content.query_column_names + [ :latest, :versions ] ).each do | col |
      if q.gsub!(/(?:\b|\s*,)#{col}:([^,\s]+)(?:\s*|,\s*)/i, '')
        case col
        when :latest, :versions
          send("#{col}=", str_to_bool($1))
        else
          (subquery ||= { })[col] = $1
        end
      end
    end
    if subquery
      h = (search_options[:subquery] ||= { })
      h[:subquery] = { :params => subquery }
    end
    
    q.gsub!(/\A\s+|\s+\Z/, '')
    unless q.blank?
      h = (search_options[:subquery] ||= { })
      p = (h[:params] ||= { })
      p[:content_key] ||= q
      p[:data] ||= q
      h[:ilike] = true
      h[:or] = true
    end
    
    self.options = search_options
  end


  def str_to_bool str
    return false unless str
    ! ! (str =~ /\A\s*[ty1-9]/i)
  end


  # TODO: Switch to Content::Version if :version parameter is given.
  def sql opts = EMPTY_HASH
    opts = options.merge(opts)

    join_tables = BELONGS_TO.map{|x| x.to_s.pluralize} + [ ContentStatus.table_name ]
    join_tables.uniq!

    tables = join_tables.dup
    clauses = [ ]

    @model_class = Content::Version if self.latest || self.versions

    connection = model_class.connection

    unless (version_list_name = params[:version_list_name]).blank?
      @model_class = Content::Version
      tables << 
        (t1 = VersionListName.table_name) << 
        (t2 = VersionList.table_name) <<
        (t3 = VersionListContent.table_name)
      clauses << 
        "#{t1}.name               = #{connection.quote(version_list_name)}" <<
        "#{t3}.version_list_id   = #{t1}.version_list_id"
    else
      version_list_name = nil
    end

    unless (version_list_id = params[:version_list_id]).blank?
      version_list_id = version_list_id.to_i
      @model_class = Content::Version
      tables <<
        (t3 = VersionListContent.table_name)
      clauses << 
        "#{t3}.version_list_id   = #{connection.quote(version_list_id)}"
    else
      version_list_id = nil
    end

    table_name = 
      opts[:table_name] || 
      model_class.table_name

    if version_list_name || version_list_id 
      tables << 
        (t3 = VersionListContent.table_name)
      clauses << 
        "#{t3}.content_version_id = contents.id"
    end

    order_by = Content.order_by
    order_by = order_by.split('), (').join("),\n  (") 
    order_by << ",\n  version DESC" if self.versions
    
    select_values = "contents.*"
    if self.latest
      select_values = 'cv.*'
    end

    if opts[:count]
      select_values = "COUNT(#{select_values})"
      order_by = nil
    end


    ##################################################################
    # Generate SQL
    #

    sql = ''

    if self.latest
      sql << "SELECT #{select_values} FROM #{model_class.table_name} AS cv"
      sql << "\nWHERE cv.id IN (\n"
      select_values = 'MAX(contents.id)'
    end

    sql << <<"END"
SELECT #{select_values}
FROM #{table_name} AS contents, #{tables.uniq * ', '}, content_types
WHERE
    #{join_tables.map{|x| "(#{x}.id = contents.#{x.to_s.singularize}_id)"} * "\nAND "}
AND (content_types.id = content_keys.content_type_id)
END

    # Join clauses:
    unless clauses.empty?
      sql << "\nAND " << (clauses.map{| x | "(#{x})"} * "\nAND ")
    end

    # Search clauses:
    unless (where = sql_where_clauses(opts)).empty?
      sql << "\nAND " << where
    end

    if self.latest
      sql << "\nAND contents.content_id = cv.content_id" 
      sql << "\n)"
    end

    # Ordering:
    if order_by
      sql << "\nORDER BY\n  " << order_by
    end

    # Limit:
    if x = (opts[:limit])
      sql << "\nLIMIT #{x}"
    end

    if opts[:dump_sql] # || true
      $stderr.puts "  params = #{params.inspect}"
      $stderr.puts "  sql =\n #{sql}"
      # raise "LKSDJFLKSJDF"
    end

    sql
  end


  # Returns the WHERE clause SQL for this query.
  # Include any subqueries.
  def sql_where_clauses opts = { }
    opts = options.merge(opts)

    sql = ''

    clauses = [ ]

    # Construct find :conditions.
    (Content.query_column_names).
      each do | column |
      if params.key?(column)
        value = params[column]
        field_is_int = false
        field = 
          case column 
          when :id, :version
            field_is_int = true
            "contents.#{column}"
          when :uuid, :md5sum
            "contents.#{column}"
          when :data
            "convert_from(contents.data, 'UTF8')" 
          when :content_key_uuid
            'content_keys.uuid'
          else 
            case column.to_s
            when /\A(.+)_id\Z/
              field_is_int = true
              "#{$1.pluralize}.id"
            else
              "#{column.to_s.pluralize}.code"
            end
          end
 
        # Coerce value.
        case value
        when Symbol
          value = value.to_s
        when Regexp
          value = value.inspect
        when String
          value = value
        when ActiveRecord::Base
          value = value.id
          field = "#{column.to_s.pluralize}.id"
        end

        # $stderr.puts "#{column} = #{value.inspect}"

        # Handle different match types
        case
        when opts[:exact]
          field += ' = %s'

        when opts[:like]
          field += ' LIKE %s'
          value = value.to_s

        #Postgres-specific case-insensitive like
        when opts[:ilike]
          field += ' ILIKE %s'
          value = value.to_s

          # Match NULL
        when value == 'NULL'
          field += ' IS NULL'

          # Match !NULL
        when value == '!NULL'
          field += ' IS NOT NULL'

          # Match Regexp
        when value =~ /^\/(.*)\/$/ || value =~ /^\~(.*)$/
          value = $1
          field += ' ~ %s'

          # Match not Regexp
        when value =~ /^!\/(.*)\/$/ || value =~ /^!\~(.*)$/
          value = $1
          field += ' !~ %s'

          # Match not String.
        when (value = value.to_s.dup) && value.sub!(/\A!/, '')
          field = "#{field} IS NULL OR #{field} <> %s"

          # Relational:
        when (value = value.to_s.dup) && value.sub!(/\A(<|>|<=|>=|=|<>|!=)/, '')
          op = $1
          op = '<>' if op == '!='
          field += ' ' + op + ' %s'

          # Match exact.
        else
          field += ' = %s'
        end

        if ! opts[:like] && field_is_int 
          value &&= value.to_i
        end

        clauses << "(#{field % Content.connection.quote(value)})"
      end
    end

    unless clauses.empty?
      sql << "(\n    #{clauses * (opts[:or] ? "\nOR  " : "\nAND ")}\n    )"
    end

    # Subquery clauses:
    if @subquery && ! (where = @subquery.sql_where_clauses).empty?
      sql << "\nAND " unless sql.empty?
      sql << where
    end

    sql
  end


  # Returns the rows of this query.
  # Results are not cached.
  def find opt = nil
    opt ||= :all
   
    opts = { }
    opts[:limit] = 1 if opt == :first

    # self.sql sets self.model_class.
    this_sql = self.sql(opts)
    result = model_class.find_by_sql(this_sql)

    result = result.first if opt == :first

    result
  end


  # Returns the cached row count of this query.
  def count
    @count ||=
      begin
        # self.sql sets self.model_class.
        this_sql = sql(:count => true)
        model_class.connection.
          query(this_sql).
          first.first
      end
  end


  # Returns the cached pagination of this query.
  def paginate opts = { }
    @paginate ||= 
      begin
        # self.sql sets self.model_class.
        this_sql = sql
        model_class.
          paginate_by_sql(this_sql, opts)
      end
  end


end # class

end # class
