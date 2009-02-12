# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include RoleRequirementSystem
  include CapabilityRequirementSystem


  helper :all # include all helpers, all the time

  before_filter :track_controller!
  def track_controller!
    Thread.current[:'ApplicationController.current'] = self
  end
  private :track_controller!

  def self.current
    Thread.current[:'ApplicationController.current']
  end


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
      user = User.create!({
                            :login => login, 
                            :name => login, 
                            :email => "#{login}@localhost.com",
                            :password => password,
                            :password_confirmation => password,
                          })
      user.roles << Role['__default__']
      user.roles << Role['content_editor']
    end
  end
  protected :before_basic_auth


  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery :secret => '4181fa48888dd663ae6eb0d5843778ef'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password


  def html_title
    "Contenter : #{self.class.name.sub(/Controller$/, '').underscore.humanize.downcase} : #{self.action_name.humanize.downcase}"
  end
  helper_method :html_title


  def streamlined_branding
    result = ''
    result << %Q{<div><span><a href="/">Contenter</a></span> <span style="float: right; font-size: 75%;">}
    if logged_in?
      result << %Q{<a href="/users/#{current_user.id}">#{current_user.name}</a> <a href="/sessions/destroy">logout</a>}
    else
      result << %Q{<a href="/session/new">login</a>}
    end
    result << %Q{</span></div>}
    result
  end
  helper_method :streamlined_branding


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
     :revision_list_name,
     :revision_list,
     :user,
     :role,
     :capability,
     :role_capability,
    ]

    menus.map! do | x |
      title = x.to_s.pluralize.humanize.titleize
      controller = x.to_s.pluralize
      if params[:controller] == controller
        title = "<u>#{title}</u>"
      end
      [ title,
        { :controller => controller, :action => :list }
      ]
    end

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

    user = current_user || User[:__default__]
    menus = menus.select do | (title, opts) |
      user.has_capability?(opts)
    end

    menus
  end
  helper_method :streamlined_top_menus


  def _streamlined_side_menus
    menus = [ :list, :new ]

    # Show id-based actions.
    if params[:id]
      [ :show, :edit, :edit_as_new ].each do | action |
        menus << [ action, { :action => action, :id => :id } ]
      end
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
