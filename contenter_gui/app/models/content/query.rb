

class Content
#
# Searches Content and Content::Version
#
class Query
  # The class to query against: Content or Content::Version
  attr_accessor :model_class

  # The query parameters.
  attr_accessor :params

  # The query options.
  #   :limit
  #   :exact
  #   :like
  attr_accessor :options
  
  # A subquery.
  # Can be a Hash or a Content::Query object.
  attr_accessor :subquery


  def initialize options = EMPTY_HASH
    @model_class = options[:model_class] || Content
    @params = options[:params]
    @subquery = options[:subquery]
    @options = options
    if Hash === @subquery
      @subquery = self.class.new(@subquery)
    end
  end


  # TODO: Switch to Content::Version if :version parameter is given.
  def sql opts = EMPTY_HASH
    opts = options.merge(opts)

    tables = BELONGS_TO.map{|x| x.to_s.pluralize}
    clauses = [ ]
    connection = model_class.connection

    unless (revision_list_name = params[:revision_list_name]).blank?
      @model_class = Content::Version
      tables << 
        (t1 = RevisionListName.table_name) << 
        (t2 = RevisionList.table_name) <<
        (t3 = RevisionListContent.table_name)
      clauses << 
        "#{t1}.name               = #{connection.quote(revision_list_name)}" <<
        "#{t3}.revision_list_id   = #{t1}.revision_list_id"
    else
      revision_list_name = nil
    end

    unless (revision_list_id = params[:revision_list_id]).blank?
      revision_list_id = revision_list_id.to_i
      @model_class = Content::Version
      tables <<
        (t3 = RevisionListContent.table_name)
      clauses << 
        "#{t3}.revision_list_id   = #{connection.quote(revision_list_id)}"
    else
      revision_list_id = nil
    end

    table_name = 
      opts[:table_name] || 
      model_class.table_name

    if revision_list_name || revision_list_id 
      tables << 
        (t3 = RevisionListContent.table_name)
      clauses << 
        "#{t3}.content_version_id = #{table_name}.id"
    end

    order_by = Content.order_by

    select_values = "#{table_name}.*"
    if opts[:count]
      select_values = "COUNT(#{select_values})"
      order_by = nil
    end

    sql = <<"END"
SELECT #{select_values}
FROM #{table_name}, #{tables.uniq * ', '}, content_types
WHERE
    #{BELONGS_TO.map{|x| "(#{x.to_s.pluralize}.id = #{table_name}.#{x}_id)"} * "\nAND "}
AND (content_types.id = content_keys.content_type_id)
END

    unless clauses.empty?
      sql << "\nAND " << (clauses.map{| x | "(#{x})"} * "\nAND ")
    end

    # Search clauses:
    unless (where = sql_where_clauses(opts)).empty?
      sql << "\nAND  " << where
    end

    # Ordering:
    if order_by
      sql << "\nORDER BY\n  " << order_by
    end

    # Limit:
    if x = (opts[:limit])
      sql << "\nLIMIT #{x}"
    end

    if opts[:dump_sql]
      $stderr.puts "  params = #{params.inspect}"
      $stderr.puts "  sql =\n #{sql}"
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
    Content.find_column_names.each do | column |
      if params.key?(column)
        value = params[column]
        field = 
          case column 
          when :id, :version, :uuid, :md5sum
            "contents.#{column}"
          when :data
            "convert_from(contents.data, 'UTF8')" 
          when :content_key_uuid
            'content_keys.uuid'
          else 
            "#{column.to_s.pluralize}.code"
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

        # Handle meta values.
        case
        when opts[:exact]
          field += ' = %s'

        when opts[:like]
          field += ' LIKE %s'
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

        unless opts[:like]
          case column
          when :version
            value = value.to_i
          end
        end

        clauses << "(#{field % Content.connection.quote(value)})"
      end
    end

    unless clauses.empty?
      sql << "(\n    #{clauses * (opts[:or] ? "\nOR  " : "\nAND ")}\n    )"
    end

    # Subquery clauses:
    if @subquery && ! (where = @subquery.sql_where_clauses).empty?
      sql << "\nAND  " unless sql.empty?
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

    result = model_class.find_by_sql(sql(opts))

    result = result.first if opt == :first

    result
  end


  # Returns the cached row count of this query.
  def count
    @count ||=
      model_class.connection.
      query(sql(:count => true)).
      first.first
  end


  # Returns the cached pagination of this query.
  def paginate opts = { }
    @paginate ||= 
      model_class.
      paginate_by_sql(sql, opts)
  end


end # class

end # class
