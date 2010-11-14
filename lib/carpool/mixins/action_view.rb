module Carpool
  module Mixins
    module ActionView
      
      def carpool_login_url
        Carpool.driver_uri
      end
      
      def carpool_logout_url
        Carpool.revoke_uri
      end
      
    end
  end
end