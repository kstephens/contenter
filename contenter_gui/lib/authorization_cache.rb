
# Caches Authorization checks on User and Role.
# Controller checks cache validity with before filter.
# Authorization models notify this class when they change.
# This class updates a simple record upon the model change.
class AuthorizationCache

  # Returns the current Thread's cache.
  def self.current
    Thread.current[:'AuthorizationCache.current'] ||=
      (@@current ||=
      new)
  end


  # The top-level cache Hash.
  attr_reader :cache


  @@instance_id ||= 0


  def initialize
    @cache = { }
    @pid = $$
    @instance_id = (@@instance_id += 1)
  end


  ####################################################################
  # Cache Managment.
  #


  def role x
    _c = (@cache[:Role] ||= { })
    _c = (_c[:find] ||= { })
    (
     _c[x] ||= 
     [ _role(x) ]
     ).first
  end


  # See Role[].
  def _role x
    case x
    when Role, nil
      x
    when Integer
      Role.find(x) ||
        raise("Cannot find Role id=#{x.inspect}")
    when String, Symbol
      Role.find(:first, :conditions => { :name => x.to_s } ) ||
        raise("Cannot find Role name=#{x.inspect}")
    end
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


  # Converts Capability, Hash to a String.
  def normalize_capability cap
    cap = cap.name if cap.respond_to?(:name)
    if Hash === cap
      cap = "controller/#{cap[:controller] || '*'}/#{cap[:action] || '*'}"
    end
    cap = cap.to_s unless String === cap
    cap
  end


  ####################################################################
  # Cache Managment.
  #


  # Flushes the cache.
  def flush!
    unless @cache.empty?
      $stderr.puts "  FLUSHING CACHE!"
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
      $stderr.puts " check! #{c.inspect}"
      @last_check = c.changed_at
      flush!
    end
    self
  end


  # Callback for any Auth object that had saved changes.
  def auth_changed! object = nil
    $stderr.puts "  auth_changed! #{object.inspect}"
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
  end
end

