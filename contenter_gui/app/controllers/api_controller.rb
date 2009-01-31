class ApiController < ApplicationController
  def index
    search
  end


  def list
    dump_by_params params
  end


  def dump
    dump_by_params params
  end


  def search
    if p = params[:search]
      p = p.dup
      p.keys.each do | k |
        p.delete(k) if p[k].empty?
      end
      if c = params[:columns]
        # $stderr.puts "c = #{c.inspect}"
        columns = Content.find_column_names.select{ |x| c[x].to_i != 0 }
        p[:columns] = columns.join(',')
      end
      redirect_to :action => :dump, :params => p
    end
  end


  def update
    api = Content::API.new
    # $stderr.puts "   request.body = #{request.body.class}"
    api.load_from_stream(request.body)
    render :text => api.result.to_yaml, :content_type => 'text/plain'
  end


  def dump_by_params params
    api = Content::API.new
    result = api.dump(params)
    render :text => result, :content_type => 'text/plain'
  end
  private :dump_by_params

end

