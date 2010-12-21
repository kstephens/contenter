
module Garm
  class Api
    class Impl < self
      def authenticate params
        session
      end

      # Refactor from User.
      def can? capability, user = nil
        user = self.current_user
      end

      # Refactor from CapabilityController
      def who_has params
      end
    end

    class Session
      attr_accessor :api, :user, :capabilities
      
      def can? capability
        api.can? capability, user
      end
    end
  end
end
