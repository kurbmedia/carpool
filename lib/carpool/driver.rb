module Carpool
  
  class Driver
    
    class << self
      
      def passengers
        @passengers ||= []
      end
      
      def passenger(url, options = {})
        options[:site_key] ||= Carpool.generate_site_key(url)
        passengers << { url => options }
      end
      
    end
    
    def initialize(app)
      @app = app
      yield Carpool::Driver if block_given?
      self
    end
    
    def call(env)
      
      return unless env['PATH_INFO'] == "/sso/authenticate"
      
      @env = env
      result  = @app.call(env)
      
      unless env['HTTP_REFERRER'].nil?
        cookies[:referring_domain] = URI.parse(env['HTTP_REFERRER']).host
        cookies[:redirect_to]      = env['HTTP_REFERRER']
      end
      
    end
        
    def session
      @env['rack.session']
    end
    
    def cookies
      session['carpool.cookies'] ||={}
    end
    
  end
end