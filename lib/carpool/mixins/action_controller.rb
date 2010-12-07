module Carpool
  module Mixins
    module ActionController
      
      def carpool_login_url
        Carpool.driver_uri
      end
      
      def carpool_logout_url
        Carpool.revoke_uri
      end
      
      def carpool_manager
        carpool_rack_env['carpool']
      end
            
      private
      
      def carpool_rack_request
        @_request = Rack::Request.new(carpool_rack_env)
      end
      
      def carpool_rack_env
        (defined?(env) ? env : request.env)
      end
      
    end
  end
end