class CapabilitiesController < ApplicationController
  layout "streamlined"
  acts_as_streamlined
  require_capability :ACTION

  def who_has
    case
    when ! (p = params[:uri]).blank?
      p = CGI.unescape(p)
      p.sub!(/\/\d+\Z/, '')
      @capability_pattern = "controller#{p}"
    when ! (p = params[:capability_pattern]).blank?
      @capability_pattern = p
      # self.instance = self.model.find(:first, :conditions => { :name => p })
    when ! (p = params[:id]).blank?
      self.instance = self.model.find(p.to_i)
    end

    @capability_expansion = [ self.instance.name ] if self.instance
    @capability_expansion ||= @capability_pattern ? CapabilityHelper.capability_expand(@capability_pattern) : [ ]

    @roles = Role.all_with_capability(@capability_expansion).sort_by{|r| r.name}
    @roles.map! do | role |
      [ role, role.role_capabilities.to_a.find{|rc| rc.allow && @capability_expansion.include?(rc.capability.name)} ]
    end

    @users = { }
    @roles.each{ | r | r.first.users.each{ | u | @users[u.id] = User[u.id] } }
    @users = @users.values
    @users = @users.select{| u | u.has_capability?(@capability_pattern) }
    @users = @users.sort_by{|u| u.login}
    
    @capability_expansion = @capability_expansion.map do | cap |
      [ cap, Capability[cap] ]
    end
    @capability_expansion.each do | x |
      x[2] = x[1] && self.instance && x[0] == self.instance.name
    end
  end

  def _streamlined_side_menus
    menus = super

    menus +=
      [
       [
        "Who Has",
        { :action => :who_has, :id => self.instance }
       ],
      ]
       
    menus
  end

end

