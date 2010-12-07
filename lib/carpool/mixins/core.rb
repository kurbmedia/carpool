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
        
        def destroy_session!
          cleanup_session!
          carpool_cookies.delete('passenger_tokens')
        end
        
        def manager
          @env['carpool']
        end
        
        def carpool_passenger_tokens
          carpool_cookies['passenger_tokens'] ||= []
        end
        
        def update_authentication!(new_token)
          carpool_passenger_tokens << new_token
          carpool_passenger_tokens.uniq!
        end
        
      end
    end
    
  end
end