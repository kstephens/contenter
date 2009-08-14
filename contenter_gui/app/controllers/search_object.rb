# Generic SearchObject for views/content/_list_results.html.erb.
class SearchObject
  attr_accessor :search
  attr_accessor :query_options
  attr_accessor :columns

  attr_reader :opts

  def initialize opts
    $stderr.puts "\n  #{self.class} opts = #{opts.inspect}"
    case opts
    when String
      opts = { :search => opts }
    end

    @search = ''
    @query_options = { }
    @columns = Content::LIST_COLUMNS

    opts ||= { }

    @opts = opts

    opts.each do | k, v |
      send("#{k}=", v)
    end
  end

  # Returns a cached Content::Query object.
  def query
    @query ||= 
      Content::Query.new(query_options.merge(:user_query => search))
  end
end

