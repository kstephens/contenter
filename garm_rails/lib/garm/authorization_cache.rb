module Garm

# Caches Authorization checks on User and Role.
# Controller checks cache validity with before filter.
# Authorization models notify this class when they change.
# This class updates a simple record upon the model change.
class AuthorizationCache

  # Returns the current Thread's cache.
  def self.current
    Thread.current[:'Garm::AuthorizationCache.current'] ||=
      (@@current ||=
      new)
  end


  # The top-level cache Hash.
  attr_reader :cache

  attr_accessor :logger


  @@instance_id ||= 0


  def initialize api = nil
    @api = api
    @cache = { }
    @pid = $$
    @instance_id = (@@instance_id += 1)
  end


  def _log msg = nil
    if @logger
      msg ||= yield
      @logger.puts "#{self.class} #{msg}"
    end
  end


  ####################################################################
  # Model caching.
  #


  # Will not raise if User#login = "somename" does not exist.
  def user x
    _c = (@cache[:User] ||= { })
    _c = (_c[:find] ||= { })
    result =
      _c[x] ||= 
      begin
        result = [ _user(x) ]
        if result.first
          _c[result.first.id] =
            _c[result.first.login] =
            _c[result.first.login.to_sym] = result
        end
        result
      end
    result.first
  end


  # See User[].
  def _user x
    case x
    when User, nil
      x
    when Integer
      User.find(x)
    when String, Symbol
      User.find(:first, :conditions => { :login => x.to_s } )
    else
      raise TypeError
    end
  end


  def role x
    _c = (@cache[:Role] ||= { })
    _c = (_c[:find] ||= { })
    result = 
      _c[x] ||= 
      begin
        result = [ _role(x) ]
        if result.first
          _c[result.first.id] = 
            _c[result.first.name] = 
            _c[result.first.name.to_sym] = result
        end
        result
      end
    result.first
  end


  # See Role[].
  def _role x
    case x
    when Role, nil
      x
    when Integer
      Role.find(x)
    when String, Symbol
      Role.find(:first, :conditions => { :name => x.to_s } )
    else
      raise TypeError
    end
  end


  # Will not raise if Capability#name = "somename" does not exist.
  def capability x
    _c = (@cache[:Capability] ||= { })
    _c = (_c[:find] ||= { })
    result =
     _c[x] ||= 
      begin
        result = [ _capability(x) ]
        if result.first
          _c[result.first.id] =
            _c[result.first.name] =
            _c[result.first.name.to_sym] = result
        end
        result
      end
    result.first
  end


  # See Capability[].
  def _capability x
    case x
    when Capability, nil
      x
    when Integer
      Capability.find(x)
    when String, Symbol
      Capability.find(:first, :conditions => { :name => x.to_s } )
    else
      raise TypeError, "Given #{x.class.name}"
    end
  end


  ####################################################################
  # Computation cache.
  #

  # Converts Capability, Hash to a String.
  def normalize_capability cap
    cap = cap.name if cap.respond_to?(:name)
    if Hash === cap
      cap = "controller/<<#{cap[:controller] || '*'}>>/<<#{cap[:action] || '*'}>>"
    end
    cap = cap.to_s unless String === cap || Array === cap
    cap
  end


  # See Role._has_capability?
  def Role_has_capability? role, cap
    cap = normalize_capability cap

    _c = (@cache[:Role] ||= { })
    _c = (_c[role.id] ||= { })
    _c = (_c[:has_capability?] ||= { })
    (
     _c[cap] ||= 
     [ role._has_capability?(cap) ]
     ).first
  end


  # See Role._capability
  def Role_capability role
    _c = (@cache[:Role] ||= { })
    _c = (_c[role.id] ||= { })
    (
     _c[:capability] ||= 
     [ role._capability ]
     ).first
  end


  # See Role._has_capability?
  def User_has_capability? user, cap
    cap = normalize_capability cap

    _c = (@cache[:User] ||= { })
    _c = (_c[user.id] ||= { })
    _c = (_c[:has_capability?] ||= { })
    (
     _c[cap] ||= 
     [ user._has_capability?(cap) ]
     ).first
  end



  ####################################################################
  # Cache Managment.
  #


  # Flushes the cache.
  def flush!
    unless @cache.empty?
      _log { "  FLUSHING CACHE!" }
      @cache.clear
    end
    self
  end


  # Check the time of the last auth_changed!
  def check!
    @auth_change = nil
    c = auth_change
    c.reload
    if (! @last_check) || @last_check != c.changed_at
      _log { " check! #{c.inspect}" }
      @last_check = c.changed_at
      flush!
    end
    self
  end


  # Callback for any Auth object that had saved changes.
  def auth_changed! object = nil
    _log { "  auth_changed! #{object.inspect}" }
    flush!
    @last_check = auth_change.changed_at = Time.now
    auth_change.save! rescue nil
    # auth_change.class.destroy(:all, :conditions => [ 'id <> ?', auth_change.id ])
    self
  end


  # Returns the Object containing the time of the last auth_changed!
  def auth_change
    @auth_change ||=
      AuthChange.transaction do 
        AuthChange.find(:first, :order => 'id') || 
        AuthChange.create!(:changed_at => Time.now)
      end

    # Retry incase of transactional race condition, VERY VERY UNLIKELY
  rescue Exception => err
    $stderr.puts "#{self.class.name}#auth_change ERROR #{err.inspect}"
    sleep 1
    retry
  end
end

end # module
