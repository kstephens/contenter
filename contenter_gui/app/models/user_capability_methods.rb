module UserCapabilityMethods
  # Returns true if this User allows the Capability.
  # Returns false if this User does not allow the Capability.
  # Returns nil if its inconclusive.
  def has_capability? cap
    cap = cap.name if cap.respond_to?(:name)
    if Hash === cap
      cap = "controller/#{cap[:controller]}/#{cap[:action] || '*'}"
    end
    cap = cap.to_s unless String === cap
    
    ((@has_capability ||= { })[cap] ||= 
     [ _has_capability?(cap) ]
     ).first
  end

  def _has_capability?(capability)
    allow = nil
    deny = nil

    roles.each do | role |
      case role.has_capability?(capability)
      when true
        allow = true
      else false
        deny = true
      end
    end

=begin
    $stderr.puts "    User[#{self.name.inspect}]._has_capability?(#{capability.inspect})"
    $stderr.puts "      allow = #{allow.inspect}"
    $stderr.puts "      deny  = #{deny.inspect}"
=end
    
    return true if allow == true
    return false if deny == true
    nil
  end


=begin
  alias :__has_capability? :_has_capability?

  def _has_capability?(capability)
    result = __has_capability?(capability)
    $stderr.puts "    User[#{self.name.inspect}]._has_capability?(#{capability.inspect}) => #{result.inspect}"
    result
  end
=end

end


