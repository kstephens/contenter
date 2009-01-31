# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include RoleRequirementSystem
  include CapabilityRequirementSystem


  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '4181fa48888dd663ae6eb0d5843778ef'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password

  def streamlined_branding
    %Q{<a href="/">Contenter</a><span style="align: left;">#{request.env["REMOTE_USER"]}</span>}
  end
  helper_method :streamlined_branding


  def streamlined_top_menus
    menus = [
     :content,
     :content_key,
     :content_type,
     :language,
     :country,
     :brand,
     :application,
     :mime_type,
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

    menus <<
      [ 'Api',
        { :controller => :api, :action => :search }
      ]

    menus
  end
  helper_method :streamlined_top_menus


  def streamlined_side_menus
    menus = [ :list, :new ]
    menus = menus.map { | x |
      x = x.to_s
      title = x.humanize
      if params[:action] == x
        title = "<u>#{title}</u>"
      end
      [ title, { :action => x } ]
    }
    if params[:id]
      flips = [ :edit, :edit_as_new, :show ]
      [ flips, flips.reverse ].each do | x, y |
        if action_name == x.to_s
          menus << [ "#{y.to_s.humanize} --->", 
                     { :action => y, :id => params[:id] }
                   ] 
        end
      end
    end
    menus
  end
  helper_method :streamlined_side_menus


  def streamlined_footer
    '<a href="http://kurtstephens.com">Copyright 2008-2009 Kurt Stephens</a>'
  end
  helper_method :streamlined_footer
end
