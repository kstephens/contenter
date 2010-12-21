module UserCapabilityMethods
  def self.included base
    super
    base.class_eval do 
      include Garm::AuthorizationCache::Methods
      
      auth_cache_delegate :has_capability?
    end
  end


  # Tests each Users role for a Capability.
  # Returns true if any User's role allows the Capability.
  # Returns false if any User's role denies the Capability.
  # Returns nil if inconclusive.
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
    
    case
    when allow == true
      true
    when deny == true
      false
    else
      nil
    end
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


