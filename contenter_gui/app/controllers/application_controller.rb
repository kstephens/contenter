# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include RoleRequirementSystem
  include CapabilityRequirementSystem
  include SessionVersionList

  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery :secret => '4181fa48888dd663ae6eb0d5843778ef'

  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password


  ####################################################################
  # Controller/view/model support
  #

  before_filter :track_controller!
  def track_controller!
    Thread.current[:'ApplicationController.current'] = self
  end
  private :track_controller!


  def self.current
    Thread.current[:'ApplicationController.current']
  end


  ####################################################################
  # ModelCache support
  #


  before_filter :reset_model_cache!
  def reset_model_cache!
    ModelCache.reset!
    ModelCache.create!
  end
  helper_method :reset_model_cache!
  
 

  ####################################################################
  # Auth support
  #

  before_filter :auth_cache_check!
  def auth_cache_check!
    AuthorizationCache.current.check!
  end
  private :auth_cache_check!


  before_filter :track_user!
  def track_user!
    UserTracking.current_user = Proc.new { self.current_user }
    true
  end
  private :track_user!

  
  # HACK FOR protected current_user method.
  def _current_user
    current_user
  end
 

  # Creates a new user with default and content_editor roles.
  def before_basic_auth login, password
    # Create a new user?
    unless User[login]
      creator = Contenter::AutoUserCreator.new
      user = creator.create_user!(:login => login, :password => password)
    end
  end
  protected :before_basic_auth


  ####################################################################
  # Streamlined support
  #


  def html_title
    "Contenter : #{self.class.name.sub(/Controller$/, '').underscore.humanize.downcase} : #{self.action_name.humanize.downcase}"
  end
  helper_method :html_title


  def __link_to text, opts = { }
    opts[:controller] ||= params[:controller] if opts[:action]

    link = ''
    link << "/#{opts[:controller]}" if opts[:controller]
    link << "/#{opts[:action]}" if opts[:action]
    if x = opts[:id]
      x = x.id if respond_to?(:id)
      link << "/#{x}"
    end

    %Q{<a href="#{link}">#{text}</a>}
  end
  helper_method :__link_to


  def string_pluralize(n, str)
    if n == 1
      "#{n} #{str}"
    else
      "#{n} #{str.pluralize}"
    end
  end
  helper_method :string_pluralize


  def streamlined_branding
    result = ''

    result << %Q{<div><span><a href="/">Contenter</a></span>}

    result << %Q{<span style="float: right; font-size: 75%;">}
    if logged_in?
      result << __link_to(current_user.name, :controller => :users, :id => current_user)
      result << ' ' << __link_to(:logout, :controller => :session, :action => :destroy)
    else
      result << __link_to(:login, :controller => :session, :action => :new)
    end
    if (x = session_version_list) && ! x.empty?
      result << ' </ br> ('
      result << __link_to(string_pluralize(x.size, 'change'), :controller => :my, :action => :changes)
      result << ')'
    end
    result << %Q{</span></div>}


    result
  end
  helper_method :streamlined_branding


  # Subclasses can override this method.
  def _streamlined_top_menus
    menus = [
     :content,
     :content_key,
     :content_type,
     :language,
     :country,
     :brand,
     :application,
     :mime_type,
     :version_list,
     :version_list_name,
     :content_status,
     :user,
     :role,
     :capability,
     :role_capability,
    ]

    menus = 
      [
       [ 'Search',
         { :controller => :search, :action => :search },
       ]
      ] + menus

    menus <<
      [ 'API',
        { :controller => :api, :action => :search }
      ]

    menus <<
      [ 'Feeds',
        { :controller => :feeds, :action => :index }
      ]

    menus
  end
  helper_method :_streamlined_top_menus


  def streamlined_top_menus
    menus = _streamlined_top_menus

    menus.map! do | x |
      next x if Array === x

      title = x.to_s.pluralize.humanize.titleize
      controller = x.to_s.pluralize
      if params[:controller] == controller
        title = "<u>#{title}</u>"
      end
      [ title,
        { :controller => controller, :action => :list }
      ]
    end

    user = current_user || User[:__default__]
    menus = menus.select do | (title, opts) |
      user.has_capability?(opts)
    end

    menus
  end
  helper_method :streamlined_top_menus


  # Subclasses can override this method.
  def _streamlined_side_menus
    menus = [ :list, :new ]

    # Show id-based actions.
    if params[:id]
      [ :show, :edit ].each do | action |
        menus << [ action, { :action => action, :id => :id } ]
      end
      menus << [ "New from this",
                 { :action => :new, :id => :id } ]
    end

    menus
  end
  helper_method :_streamlined_side_menus


  def streamlined_side_menus
    menus = _streamlined_side_menus
    
    menus = menus.map do | x |
      case x
      when Array
        x
      when Symbol, String
        [ x.to_s.humanize, { :action => x } ]
      end
    end

    # Higlight current menu title.
    menus = menus.map do | (title, opts) |
      title = title.to_s.humanize if Symbol === title
      title = title.to_s
      if action_name == opts[:action].to_s
        title = "<u>#{title}</u>"
      end
      [ title, opts ]
    end
    
    # Default controller, id.
    menus.each do | (title, opts) |
      opts[:controller] ||= (params[:controller] || self.class.name.sub(/Controller$/).underscore).to_sym
      opts[:id] = params[:id] if opts[:id] == :id
    end


    # Filter out unauthorized menus.
    user = current_user || User[:__default__]
    menus = menus.select do | (title, opts) |
      result = user.has_capability?(opts)
=begin
      $stderr.puts "   user = #{user.name}"
      $stderr.puts "   opts = #{opts.inspect}"
      $stderr.puts "     => #{result.inspect}"
=end
      result
    end

    menus
  end
  helper_method :streamlined_side_menus


  def streamlined_footer
    '<a href="http://kurtstephens.com">Copyright 2008-2009 Kurt Stephens</a>'
  end
  helper_method :streamlined_footer
end
