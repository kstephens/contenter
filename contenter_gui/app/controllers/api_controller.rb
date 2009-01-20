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

    # Get the columns requested.
    want_columns = (params[:columns] || '').split(',').map{|x| x.to_sym}

    # Get matching Content objects.
    result = Content.find_by_params(:all, params)

    # Put :data column last.
    columns = Content.find_column_names.dup
    columns.delete(:data)
    columns << :data

    # Limit to requested columns.
    unless want_columns.empty?
      columns = want_columns.select { | x | columns.include?(x) } 
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
    if (params[:unique] || '0').to_s != 0
      result.uniq!
    end

    # Sort them.
    if (params[:sort] || '0').to_s != 0
      result.sort!
    end

    # Create result Hash.
#    conn = ActiveRecord::Base.connection
    result = {
      :search_count => search_count,
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
    result = Contenter::Bulk.new(result).render_yaml.string

    render :text => result, :content_type => 'text/plain'
  end
  private :list_by_params

end

