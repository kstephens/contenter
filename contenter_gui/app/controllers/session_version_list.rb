# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

# Support for tracking versions edited during the user's session
module SessionVersionList
  def self.included base
    super
    base.class_eval do
      helper_method :session_version_list
      helper_method :create_session_version_list!
      helper_method :save_session_version_list!
      helper_method :flush_session_version_list!
      helper_method :track_in_session_version_list
  
      after_filter :save_session_version_list!
    end
  end


  # Returns the Session's current VersionList.
  def session_version_list
    @session_version_list ||=
      begin
        x = session[:version_list_id]
        x &&= VersionList.find(x)
        x
      end
  end


  # Creates or reuses a VersionList for this Session.
  def create_session_version_list!
    x = session_version_list
    if current_user
      x ||= 
        (
         @session_version_list = 
         VersionList.new(:comment => "via user #{current_user.name} session")
         )
    else
      raise "no current_user"
    end
  end

 
  def save_session_version_list!
    if current_user
      session[:version_list_id] = (x = session_version_list) && x.id
    end
  end


  def flush_session_version_list!
    if (rl = session_version_list) && ! rl.empty?
      rl.save!
      rl.notify_after_save!
    end
    @session_version_list = session[:version_list_id] = nil
    self
  end
 
 
  # Can be used as an around_filter for any
  # controller action that may modify content.
  def track_in_session_version_list
    VersionList.track_changes_in(lambda { | | create_session_version_list! }) do 
      yield
    end
    self
  end

end
