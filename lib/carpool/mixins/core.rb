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
        
        def carpool_passenger_token
          carpool_cookies['passenger_token']
        end
        
        def carpool_passenger_token=(token)
          carpool_cookies['passenger_token'] = token
        end
        
        def cleanup_session!
          ['redirect_to', 'current_passenger'].each{ |k| carpool_cookies.delete(k) }
        end
        
        def destroy_session!
          session.clear
        end
        
        def request
          @request ||= Rack::Request.new(@env)
        end
        
        def session
          @env['rack.session']
        end
        
        def set_new_path(p)
          @env['PATH_INFO'] = p
        end
        
      end
    end
    
  end
end