module Carpool
  module Mixins
    
    module Core
      def self.included(base)
        base.send :include, InstanceMethods
      end
      
      module InstanceMethods
        
        def carpool_cookies
          session['carpool.cookies'] ||= {}
        end        
        
        def request
          @request ||= Rack::Request.new(@env)
        end
        
        def session
          @env['rack.session']
        end
        
        def cleanup_session!
          carpool_cookies.delete('requesting_authentication')
          carpool_cookies.delete('passenger_uri')
        end
        
        def manager
          @env['carpool']
        end
        
      end
    end
    
  end
end