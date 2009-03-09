class ApiController < ApplicationController
  layout 'streamlined', :only => [ :index, :search ]

  require_capability :ACTION

  around_filter :track_in_session_revision_list, :only => [ :update ]

  ####################################################################


  def _streamlined_side_menus
    [ ]
  end
  helper_method :_streamlined_side_menus


  ####################################################################

  def index
    search
  end


  def list
    dump
  end


  def dump
    dump_by_params params, { :exact => true }
  end


  def search
    if p = params[:search]
      p = p.dup
      p.keys.each do | k |
        p.delete(k) if p[k].empty?
      end
      if c = params[:columns]
        # $stderr.puts "c = #{c.inspect}"
        columns = Content.display_column_names.select{ |x| c[x].to_i != 0 }
        p[:columns] = columns.join(',')
      end
      redirect_to :action => :dump, :params => p
    end
  end


  def update
    api = Content::API.new
    api.opts = params

    # $stderr.puts "   request.body = #{request.body.class}"
    flush_session_revision_list!

    rl = nil
    RevisionList.track_changes_in(
                                  lambda { | |
                                    rl ||= 
                                    RevisionList.new(:comment => "Via bulk YAML: #{api.comment}")
                                  }
                                  ) do 
      api.load_from_stream(request.body)
    end

    if rl && rl.id
      api.result[:revision_list_id] = rl.id
    end

    render :text => api.result.to_yaml, :content_type => 'text/plain'
  end


  def dump_by_params params, opts = { }
    api = Content::API.new
    api.opts = opts
    result = api.dump(params)
    render :text => result, :content_type => 'text/plain'
  end
  private :dump_by_params

end

