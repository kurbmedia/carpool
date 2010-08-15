module Carpool
  module Mixins
    
    module Core
      def self.included(base)
        base.send :include, InstanceMethods
      end
      
      module InstanceMethods
        def session
          @env['rack.session']
        end

        def cookies
          session['carpool.cookies'] ||= {}
        end
      end
    end
    
  end
end