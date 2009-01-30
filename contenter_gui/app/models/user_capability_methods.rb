module UserCapabilityMethods
  # Returns true if this User allows the Capability.
  # Returns false if this User does not allow the Capability.
  # Returns nil if its inconclusive.
  def has_capability? cap
    cap = cap.name if cap.respond_to?(:name)
    cap = cap.to_s unless String === cap
    
    ((@has_capability ||= { })[cap] ||= 
     [ _has_capability?(cap) ]
     ).first
  end

  def _has_capability?(capability)
    roles.each do | role |
      allow = role.has_capability?(capability)
      return allow unless allow.nil?
    end
    return nil
  end


end


