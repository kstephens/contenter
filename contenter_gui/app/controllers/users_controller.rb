
class UsersController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  # include AuthenticatedSystem
  
  layout "streamlined"
  acts_as_streamlined
  # require_capability :ACTION


  def _streamlined_side_menus
    menus = super

    menus += [
       [ 'Become User',
         { :controller => 'sessions', :action => 'become_user' }
       ],
       current_user != real_user ?
       [
        "Become #{real_user.login.inspect}",
        { :controller => 'sessions', :action => 'become_real_user' },
       ] : nil
      ]

    if params[:id]
      menus +=
        [
         [
          "Become This User",
          { :controller => :sessions, :action => :become_user, :id => :id }
         ],
        ]
    end

    menus
  end


  # render new.rhtml
  def new
    @user = User.new
  end
 
  def create
    logout_keeping_session!
    @user = User.new(params[:user])
    success = @user && @user.save
    if success && @user.errors.empty?
            # Protects against session fixation attacks, causes request forgery
      # protection if visitor resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset session
      self.current_user = @user # !! now logged in
      redirect_back_or_default('/')
      flash[:notice] = "Thanks for signing up!  We're sending you an email with your activation code."
    else
      flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
      render :action => 'new'
    end
  end

  def _user
    @user
  end
  helper_method :_user
end

