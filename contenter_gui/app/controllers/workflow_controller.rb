# Moves content items through a workflow (stub class required by streamlined)
class Workflow; end

class WorkflowController < ApplicationController
  layout "streamlined"

  include CrudController

  require_capability :ACTION
  before_filter :require_post, :only => [ :perform_status_action ]

  before_filter :id_to_status_action, :only => [ :list ]
  
  def id_to_status_action
    if status_action = params.delete(:id)
      params[:status_action] ||= status_action
    end
  end
  private :id_to_status_action


  #########################################
  #  Primary Actions

  # Shows content items upon which params[:status_action] can be performed
  def list
    status_to_fetch = 
      case status_action
      when :approve
        "created|modified"
      when :release
        "approved"
      else
        raise "Invalid status_action #{status_action.inspect}"
      end

    search_params = {
      :content_status => status_to_fetch,
    }
    search_params.update(params)
    search_params.delete(:action)
    search_params.delete(:controller)
 
    $stderr.puts "   ### search_params => #{search_params.inspect}"
    @search = SearchObject.new( :query_options => {
            :params => search_params,
         }
     )
  end

  # Effects the params[:status_action] upon the posted content ids
  def perform_status_action
    c_ids = content_ids
    cap = ""

    logger.info { "Performing action #{status_action.inspect} on content_ids: #{c_ids.inspect}" }
    c_id = nil

    unless current_user.has_capability?(cap = "controller/<<workflow>>/<<perform_status_action>>/<<#{status_action}>>")
      raise Contenter::Error::Auth::NotAuthorized, "#{cap}"
    end

    begin

      # Each approval action gets its own version list
      comment = "Workflow action: #{status_action}"
      unless params[:version_list_comment].blank?
        comment << " Note: #{params[:version_list_comment]}"
      end

      @approval_list = VersionList.new(:comment => comment)
      @approval_list.tasks = params[:version_list] && params[:version_list][:tasks]

      content_count = 0

      Content.transaction do
        # Handle each content_type differently.
        content_types = content_objects.map{|c| c.content_type}.uniq
        content_types.each do | content_type |

          plugin = content_type.plugin_instance
          logger.info { "content_type #{content_type} plugin #{plugin}" }
          
          # Make sure the content_type's plugin can
          # support these methods:
          unless plugin.respond_to?(:plugin_around_perform_status_action)
            logger.info { "default plugin_around_perform_status_action" }
            def plugin.plugin_around_perform_status_action *args
              yield
            end
          end
          
          unless plugin.respond_to?(:plugin_perform_status_action_capability?)
            logger.info { "default plugin_around_perform_status_action?" }
            def plugin.plugin_perform_status_action_capability? *args
              true
            end
          end

          # Filter content by content_type.
          c_objs = content_objects.select { | c | c.content_type == content_type }
          logger.info { "Performing action #{status_action.inspect} on #{content_type} content_ids: #{c_objs.map{|c| c.id}.inspect}" }
        
      # Perform any plugin support around activities in
      # this block.
      # If plugin_around_perform_status_action throws exception,
      # The local transaction should rollback.
      plugin.plugin_around_perform_status_action do 
        VersionList.track_changes_in(@approval_list) do
        c_objs.
          each do | c |
            c_id = c.id

            # Check on actual content's type capability.
            if current_user.has_capability?(cap="controller/<<workflow>>/<<perform_status_action>>/<<#{status_action}>>?<<content_type>>=<<#{c.content_type.code}>>") &&
               plugin.plugin_perform_status_action_capability?(c, self)
              c.do_status_action! status_action
              content_count += 1
            else
              e = "\nCould not perform_status_action #{status_action} on content id #{c.id}. Missing capability #{cap}"
              logger.warn(e)
              flash[:notice] ||= ""
              flash[:notice] += e
            end
          end # c_ids.each
        end   # VersionList.track_changes_in
      end
        end   # content_types.each
      end     # Content.transaction

      flash[:notice] = "#{content_count} Content objects updated."

      redirect_to :controller => :version_lists, :action => :show, :id => @approval_list
    end

  end

protected

  #########################################
  #  Helper methods

  def content_objects
    @content_objects ||=
      content_ids.map { | i | Content.find(i) }
  end
  helper_method :content_objects

  # Provides the array of content_ids posted from the request.
  # Example: "content"=>{"1"=>{"id"=>"1"}, "2"=>{"id"=>"1"}}
  def content_ids
    case
    when Hash === (h = params[:content])
      h.keys.select{|k| h[k]['id'].to_i == 1}.map(&:to_i).uniq
    when params[:content_id].blank?
      [ ]
    when params[:content_id]
      [ params[:content_id].to_i ]
    else
      [ ]
    end
  end
  helper_method :content_ids

  def status_action
    @status_action ||= 
      (x = params[:status_action]) && x.to_sym
  end
  helper_method :status_action


public

  # Support for CnuContenter::Plugin::WorkflowControllerMixin
  public :current_user
  public :status_action

end
