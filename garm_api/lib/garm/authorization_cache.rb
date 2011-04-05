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
      Garm::Api.current.cache)
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
        result = [ @api._user(x) ]
        if result.first
          _c[result.first.id] =
            _c[result.first.login.dup] =
            _c[result.first.login.to_sym] = result
        end
        result
      end
    result.first
  end

  def user_roles user
    @api._user_roles user
  end

  # Will not raise if Role#name = "somename" does not exist.
  def role x
    _c = (@cache[:Role] ||= { })
    _c = (_c[:find] ||= { })
    result = 
      _c[x] ||= 
      begin
        result = [ @api._role(x) ]
        if result.first
          _c[result.first.id] = 
            _c[result.first.name.dup] = 
            _c[result.first.name.to_sym] = result
        end
        result
      end
    result.first
  end

  def role_ancestors role
    @api._role_ancestors role
  end

  # Will not raise if Capability#name = "somename" does not exist.
  def capability x
    _c = (@cache[:Capability] ||= { })
    _c = (_c[:find] ||= { })
    result =
     _c[x] ||= 
      begin
        result = [ @api._capability(x) ]
        if result.first
          _c[result.first.id] =
            _c[result.first.name.dup] =
            _c[result.first.name.to_sym] = result
        end
        result
      end
    result.first
  end

  ####################################################################
  # Computation cache.
  #

  # Converts Capability, Hash to a String.
  def normalize_capability cap
    cap = cap.name if cap.respond_to?(:name)
    # FIXME: Remove controller-centric support.
    if Hash === cap
      cap = "controller/<<#{cap[:controller] || '*'}>>/<<#{cap[:action] || '*'}>>"
    end
    cap = cap.to_s unless String === cap || Array === cap
    cap
  end


  # See Role._has_capability?
  def role_has_capability? role, cap
    cap = normalize_capability cap

    _c = (@cache[:Role] ||= { })
    _c = (_c[role.id] ||= { })
    _c = (_c[:has_capability?] ||= { })
    (
     _c[cap] ||= 
     [ @api._role_has_capability?(role, cap) ]
     ).first
  end

  # See Role._capability
  def role_capability role
    _c = (@cache[:Role] ||= { })
    _c = (_c[role.id] ||= { })
    (
     _c[:capability] ||= 
     [ @api._role_capability(role).freeze ]
     ).first
  end


  # See Role._capability_inherited
  def role_capability_inherited role
    _c = (@cache[:Role] ||= { })
    _c = (_c[role.id] ||= { })
    (
     _c[:capability_inherited] ||= 
     [ @api._role_capability_inherited(role).freeze ]
     ).first
  end

  # See User._has_capability?
  def user_has_capability? user, cap
    cap = normalize_capability cap

    _c = (@cache[:User] ||= { })
    _c = (_c[user.id] ||= { })
    _c = (_c[:has_capability?] ||= { })
    (
     _c[cap] ||= 
     [ @api._user_has_capability?(user, cap) ]
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

    # This should NEVER happen.
  rescue ActiveRecord::RecordNotFound => err
    raise err

    # Retry incase of transactional race condition, VERY VERY UNLIKELY
  rescue Exception => err
    $stderr.puts "#{self.class.name}#auth_change ERROR #{err.inspect}"
    sleep 1
    retry
  end
end

end # module
