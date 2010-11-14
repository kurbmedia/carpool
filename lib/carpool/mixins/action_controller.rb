module Carpool
  module Mixins
    module ActionController
      
      def carpool_login_url
        Carpool.driver_uri
      end
      
      def carpool_logout_url
        Carpool.revoke_uri
      end
      
      def carpool_can_authenticate?
        !([carpool_rack_env['X-CARPOOL-PAYLOAD']].flatten.empty?)
      end
      
      def carpool_user
        @_carpool_user
      end
      
      def fasten_seatbelt(user)
        Carpool::SeatBelt.new(carpool_rack_env).fasten!(user)
      end
      
      def fasten_seatbelt!(user)
        redirect_to fasten_seatbelt(user)
      end
      
      def remove_seatbelt!
        seatbelt = Carpool::SeatBelt.new(carpool_rack_env).remove!
        @_carpool_user = seatbelt.user
        seatbelt
      end
      
      def revoke_authentication!
        if Carpool.acts_as?(:driver)
          carpool_rack_env['rack.session'].delete('carpool.cookies')
        else
          redirect_to carpool_logout_url
        end
      end
      
      private
      
      def carpool_rack_env
        (defined?(env) ? env : request.env)
      end
      
    end
  end
end