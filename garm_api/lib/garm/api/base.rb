require 'garm/capability_expand'

module Garm
  module Api
    # Base class for all Garm::Api implementations.
    class Base
      include Garm::CapabilityExpand # capability_expand

      # Returns the Garm::AuthorizationCache instance for this Api.
      def cache
        @cache ||=
          Garm::AuthorizationCache.new(self)
      end

      def authenticate opts
        raise Error::SubclassResponsibility
      end

      # Returns a User object based on Integer id, String login.
      def user opts
        cache.user opts
      end

      # Returns the Role objects assigned to a User object.
      def user_roles user
        cache.user_roles user
      end

      # Returns a Role object based on Integer id, or String name.
      def role opts
        cache.role opts
      end

      # Returns a Capability object based on Integer id, or String name.
      def capability opts
        cache.capability opts
      end

      # Returns a Hash of Capability name Strings mapping to allowance booleans.
      def role_capability role
        cache.role_capability role
      end

      # Returns a Hash of Capability name Strings mapping to allowance booleans,
      # inherited from all the ancestors of a Role.
      def role_capability_inherited role
        cache.role_capability_inherited role
      end

      # Returns an Enumerable of inherited Roles of a Role (including the Role, itself).
      def role_ancestors role
        cache.role_ancestors role
      end

      # Returns true if a User has a Capability.
      def user_has_capability? user, cap
        cache.user_has_capability? user, cap
      end

      # Returns true if a Role has a Capability.
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

      def _role_ancestors role
        raise Error::SubclassResponsibility
      end


      ################################################################
      # This is the "additive inherited" algorithm.
      #

      def _role_capability_inherited role
        ca = { }
        role_ancestors(role).reverse_each do | ra |
          ca.update(role_capability(ra))
        end
        ca
      end

      # Returns true if this Role allows the Capability.
      # Returns false if this Role does not allow the Capability.
      # Returns nil if inconclusive.
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
      # Returns nil if inconclusive.
      # Uncached version.
      def _role_has_capability? role, cap
        rc = role_capability_inherited(role)

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

