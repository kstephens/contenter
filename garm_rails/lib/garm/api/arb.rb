module Garm
  module Api
    # API adapter for ActiveRecord::Base Garm models.
    class Arb < Base

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

      def _user_roles user
        user.roles
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

      # Returns a Hash of Capability name to allowance.
      def _role_capability role
        h = { }
        role.role_capabilities.each do | rc |
          h[rc.capability.name.dup.freeze] = rc.allow
        end
        h.freeze
      end

      def _role_ancestors role
        role.role_inheritances.ancestors
      end
    end
  end
end

