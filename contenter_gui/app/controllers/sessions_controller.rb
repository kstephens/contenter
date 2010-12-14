# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  layout "streamlined"

  after_filter :store_additional_session_data!

  # render new.rhtml
  def new
  end

  def create
    logout_keeping_session!
    user = User.authenticate(params[:login], params[:password])
    if user
      login_as_user! user
      redirect_back_or_default('/')
      flash[:notice] = "Logged in successfully"
    else
      note_failed_signin
      @login       = params[:login]
      @remember_me = params[:remember_me]
      render :action => 'new'
    end
  end

  def destroy
    logout_killing_session!
    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/')
  end

  # User must specify the user they want to become, and their own password.
  def become_user
    real_user # force loading of @real_user for view.

    @other_login = params[:id] || params[:other_login]

    @user = 
      User.find(:first, :conditions => { :login => @other_login.to_s }) ||
      User.find(:first, :conditions => { :id => @other_login.to_i })

    case
    when ! logged_in?
      flash[:error] = 'Not logged in.'
      redirect_to :action => :new

    when params[:real_password].blank?
      flash[:notice] = 'Enter real password below.'

    when ! @user
      flash[:error] = "No user for #{@other_login.inspect}."

      # Must give real password and have the capability to become the other user.
    when User.authenticate(current_user.login, params[:real_password]) && 
        real_user.has_capability?("controller/sessions/become_user") &&
        real_user.has_capability?("controller/sessions/become_user?login=<<#{@user.login}>>") &&
        become_user!(@user)

      # real_user will be cleared in sesssion by login_as_user!.
      save_user = self.real_user
      login_as_user!(@user) do
        self.real_user = save_user
      end
      flash[:notice] = "Became user #{current_user.login.inspect}."

    else
      flash[:error] = "Could not become user #{@user.login.inspect}."
      logger.warn "Failed become user for '#{@user.login.inspect}' from #{request.remote_ip} at #{Time.now.utc}."
    end
  end

  # User will become themselves again.
  def become_real_user
    @user = self.real_user
    if self.current_user && @user
      login_as_user! @user
    else
      flash[:error] = "Could not become user #{(@user && @user.login).inspect}"
    end
    redirect_to :back
  end

protected

  def login_as_user! user
    # Protects against session fixation attacks, causes request forgery
    # protection if user resubmits an earlier form using back
    # button. Uncomment if you understand the tradeoffs.
    reset_session
    self.current_user = user
    yield if block_given?
    store_additional_session_data!
    new_cookie_flag = (params[:remember_me] == "1")
    handle_remember_cookie! new_cookie_flag
  end


  # Track failed login attempts
  def note_failed_signin
    flash[:error] = "Couldn't log you in as '#{params[:login]}'"
    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
  end

  def store_additional_session_data!
    if user = self.current_user
      session.model.user_id = user.id
    end
    if user = self.real_user
      session[:real_user_id] = user.id
    end
  end
end
