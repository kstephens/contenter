module Garm
  module Api
    class Base
      include Garm::CapabilityExpand # capability_expand

      def cache
        @cache ||=
          Garm::AuthorizationCache.new(self)
      end

      def authenticate opts
        raise Error::SubclassResponsibility
      end

      def user opts
        cache.user opts
      end

      def user_roles user
        cache.user_roles user
      end

      def role opts
        cache.role opts
      end

      def capability opts
        cache.capability opts
      end

      def role_capability role
        cache.role_capability role
      end

      def user_has_capability? user, cap
        cache.user_has_capability? user, cap
      end

      def role_has_capability? user, cap
        cache.role_has_capability? user, cap
      end


      ################################################################
      # Implementation
      #

      def _user opts
        raise Error::SubclassResponsibility
      end

      def _user_roles opts
        raise Error::SubclassResponsibility
      end

      def _role opts
        raise Error::SubclassResponsibility
      end

      def _capability opts
        raise Error::SubclassResponsibility
      end

      def _role_capability role
        raise Error::SubclassResponsibility
      end

      # Returns true if this Role allows the Capability.
      # Returns false if this Role does not allow the Capability.
      # Returns nil if its inconclusive.
      # Uncached version.
      def _user_has_capability? user, cap
        user_roles(user).each do | role |
          allow = _role_has_capability? role, cap
          return allow unless allow.nil?
        end

        # Inconclusive.
        nil
      end

      # Returns true if this Role allows the Capability.
      # Returns false if this Role does not allow the Capability.
      # Returns nil if its inconclusive.
      # Uncached version.
      def _role_has_capability? role, cap
        rc = role_capability(role)

        # Try immediate capabilities.
        caps = capability_expand(cap)
        caps.each do | cap |
          # $stderr.puts "  Role[#{name}].capability[#{cap.inspect}]"
          allow = rc[cap]
          return allow unless allow.nil?
        end
        
        # Inconclusive.
        nil
      end


    end
  end
end

