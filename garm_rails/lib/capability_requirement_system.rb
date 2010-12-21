# module Garm # FIXME

# Main module for authentication.  
# Include this in ApplicationController to activate RoleRequirement
#
# See RoleSecurityClassMethods for some methods it provides.
#
# Refactor this to use Garm::Api.instance.user_has_capability?(user, cap).
module CapabilityRequirementSystem
  def self.included(klass)
    klass.send :class_inheritable_array, :capability_requirements
    klass.send :include, CapabilitySecurityInstanceMethods
    klass.send :extend, CapabilitySecurityClassMethods    
    klass.send :capability_requirements=, []
    
  end
  
  module CapabilitySecurityClassMethods
    
    def reset_capability_requirements!
      self.capability_requirements.clear
    end
    
    # Add this to the top of your controller to require a capability in order to access it.
    #
    # Expands to:
    #
    #   controller/:controller/:action
    #
    # Example Usage:
    # 
    #    require_capability :ACTION
    #    require_capability "contractor"
    #    require_capability "admin", :only => :destroy # don't allow contractors to destroy
    #    require_capability "admin", :only => :update, :unless => "current_user.authorized_for_listing?(params[:id]) "
    #
    # Valid options
    #
    #  * :only - Only require the capability for the given actions
    #  * :except - Require the capability for everything but 
    #  * :if - a Proc or a string to evaluate.  If it evaluates to true, the capability is required.
    #  * :unless - The inverse of :if
    #    
    def require_capability(capabilities, options = {})
      options.assert_valid_keys(:if, :unless,
        :for, :only, 
        :for_all_except, :except
      )
      
      # only declare that before filter once
      unless (@before_filter_declared||=false)
        @before_filter_declared=true
        before_filter :check_capabilities
      end
      
      # convert to an array if it isn't already
      capabilities = [ capabilities ] unless Array === capabilities
      capabilities.map! do | x |
        x = 'controller/:controller/:action' if x == nil || x == :ACTION 
        x
      end
      
      options[:only] ||= options[:for] if options[:for]
      options[:except] ||= options[:for_all_except] if options[:for_all_except]
      
      # convert any actions into symbols
      for key in [:only, :except]
        if options.has_key?(key)
          options[key] = [options[key]] unless Array === options[key]
          options[key] = options[key].compact.collect{|v| v.to_sym}
        end 
      end
      
      self.capability_requirements||=[]
      self.capability_requirements << {:capabilities => capabilities, :options => options }
    end
    
    # This is the core of CapabilityRequirement.  
    # Here is where it discerns if a user can access a controller/action or not.
    # Based on the capabilities of all the roles of the current user.
    def user_authorized_for_capability?(user, params = {}, binding = self.binding)
      return true unless Array === self.capability_requirements
      self.capability_requirements.each{| capability_requirement|
        capabilities = capability_requirement[:capabilities]
        options = capability_requirement[:options]
        # do the options match the params?
        
        controller = (params[:controller] || self.class.name.sub(/Controller$/).underscore).to_sym
        action = (params[:action] || :index).to_sym

        # check the action
        if options.has_key?(:only)
          next unless options[:only].include?( action )
        end
        
        if options.has_key?(:except)
          next if options[:except].include?( action )
        end
        
        if options.has_key?(:if)
          # execute the proc.  if the procedure returns false, we don't need to authenticate these capabilities
          next unless ( String===options[:if] ? eval(options[:if], binding) : options[:if].call(params) )
        end
        
        if options.has_key?(:unless)
          # execute the proc.  if the procedure returns true, we don't need to authenticate these capabilities
          next if ( String===options[:unless] ? eval(options[:unless], binding) : options[:unless].call(params) )
        end
        
        # check to see if they have one of the required capabilities
        @capability_pattern = nil
        passed = false
        capabilities.each { |capability|
          capability = capability.gsub(/:controller\b/, controller.to_s) if controller
          capability = capability.gsub(/:action\b/, action.to_s) if action
          @capability_pattern = capability
          if user.has_capability?(capability)
            passed = true
            break
          end
        } unless (! user || user==:false)
        
        return false unless passed
      }
      
      return true
    end
  end
  
  module CapabilitySecurityInstanceMethods
    def self.included(klass)
      raise "Because capability_requirement extends acts_as_authenticated, You must include AuthenticatedSystem first before including CapabilityRequirementSystem!" unless klass.included_modules.include?(AuthenticatedSystem)
    end
    
    def check_capabilities       
      return access_denied unless self.class.user_authorized_for_capability?(current_user, params, binding)
      
      true
    end
    
=begin
  protected
    # receives a :controller, :action, and :params.  Finds the given controller and runs user_authorized_for? on it.
    # This can be called in your views, and is for advanced users only.  If you are using :if / :unless eval expressions, 
    #   then this may or may not work (eval strings use the current binding to execute, not the binding of the target 
    #   controller)
    def url_options_authenticate?(params = {})
      params = params.symbolize_keys
      if params[:controller]
        # find the controller class
        klass = eval("#{params[:controller]}_controller".classify)
      else
        klass = self.class
      end
      klass.user_authorized_for?(current_user, params, binding)
    end
=end
  end
end
