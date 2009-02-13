class AuthorizationCache
  def self.current
    Thread.current[:'AuthorizationCache.current'] ||=
      (@@current ||=
      new)
  end


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


  def _role x
    case x
    when Integer
      Role.find(x) ||
        raise("Cannot find Role id=#{x.inspect}")
    when String, Symbol
      Role.find(:first, :conditions => { :name => x.to_s } ) ||
        raise("Cannot find Role name=#{x.inspect}")
    end
  end


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


  def Role_capability role
    _c = (@cache[:Role] ||= { })
    _c = (_c[role.id] ||= { })
    (
     _c[:capability] ||= 
     [ role._capability ]
     ).first
  end



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

  def flush!
    unless @cache.empty?
      $stderr.puts "  FLUSHING CACHE!"
      @cache.clear
    end
    self
  end


  # Check the time of the last auth_changed!
  def check!
    auth_change.reload
    if ! @last_check || @last_check < auth_change.updated_at
      @last_check = auth_change.updated_at
      flush!
    end
    self
  end


  # Callback for any Auth object that had saved changes.
  def auth_changed! object = nil
    $stderr.puts "  auth_changed! #{object.inspect}"
    flush!
    auth_change.save!
    @last_check = auth_change.updated_at
    self
  end


  # Returns the Object containing the time of the last auth_changed!
  def auth_change
    @auth_change ||=
      AuthChange.find(:first) || 
      AuthChange.create!
  end
end

