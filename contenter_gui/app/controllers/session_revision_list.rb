# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

# Support for tracking revision in the user's session
module SessionRevisionList
  def self.included base
    super
    base.class_eval do
      helper_method :session_revision_list
      helper_method :create_session_revision_list!
      helper_method :save_session_revision_list!
      helper_method :flush_session_revision_list!
      helper_method :track_in_session_revision_list
  
      after_filter :save_session_revision_list!
    end
  end


  # Returns the Session's current RevisionList.
  def session_revision_list
    @session_revision_list ||=
      begin
        x = session[:revision_list_id]
        x &&= RevisionList.find(x)
        x
      end
  end


  # Creates or reuses a RevisionList for this Session.
  def create_session_revision_list!
    x = session_revision_list
    if current_user
      x ||= 
        (
         @session_revision_list = 
         RevisionList.new(:comment => "via user #{current_user.name} session")
         )
    else
      raise "no current_user"
    end
  end

 
  def save_session_revision_list!
    if current_user
      session[:revision_list_id] = (x = session_revision_list) && x.id
    end
  end


  def flush_session_revision_list!
    if rl = session_revision_list && ! rl.empty!
      rl.save!
    end
    @session_revision_list = sesson[:revision_list_id] = nil
    self
  end
 
 
  # Can be used as an around_filter for any
  # controller action that may modify content.
  def track_in_session_revision_list
    RevisionList.track_changes_in(lambda { | | create_session_revision_list! }) do 
      yield
    end
    self
  end

end
