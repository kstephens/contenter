class ApiController < ApplicationController
  def index
    search
  end


  def list
    list_by_params params
  end


  def search
    if p = params[:search]
      p = p.dup
      p.keys.each do | k |
        p.delete(k) if p[k].empty?
      end
      if c = params[:columns]
        $stderr.puts "c = #{c.inspect}"
        columns = Content.find_column_names.select{ |x| c[x].to_i != 0 }
        p[:columns] = columns.join(',')
      end
      redirect_to :action => :list, :params => p
    end
  end


  def list_by_params params
    result = {
      :error => Exception.new("could not complete request")
    }

    want_columns = (params[:columns] || '').split(',').map{|x| x.to_sym}

    result = Content.find_by_params(:all, params)

    # Create a table of results.
    columns = Content.find_column_names + [ :content ]

    # Limit to requested columns.
    unless want_columns.empty?
      columns = want_columns.select { | x | columns.include?(x) } 
    end

    # Map results to basic values.
    result.map! do | x |
      columns.map do | c |
        v = x.respond_to?(c) ? x.send(c) : nil
        v = v.code if ActiveRecord::Base === v && v.respond_to?(:code)        
        v
      end
    end
    search_count = result.size

    # Make them unique.
    if params[:unique]
      result.uniq!
    end
    if params[:sort]
      result.sort!
    end

    # Create result Hash.
    conn = ActiveRecord::Base.connection
    result = {
      :search_count => search_count,
      :result_count => result.size,
#      :query => where.gsub('?', '%s') % 
#                values.map{|x| conn.quote(x)},
      :result_columns => columns,
      :results => result,
      :error => nil,
      # :params => self.params,
    }

  rescue Exception => error
    result = {
      :error => error.inspect,
      :error_backtrace => error.backtrace,
    }

  ensure
    # Render result as YAML.
    result[:api_version] = 1
    result = result.to_yaml

    render :text => result, :content_type => 'text/plain'
  end
  private :list_by_params

end
