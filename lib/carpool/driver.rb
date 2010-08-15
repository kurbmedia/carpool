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
      
      @env = env
      
      # Unless we are trying to authenticate a passenger, just continue through the stack.
      return @app.call(env) unless valid_request? && valid_referrer?  
      puts "Referrer: #{valid_referrer?}"
      @call_result = @app.call(env)
      attempt_authentication!
      
    end
        
    def session
      @env['rack.session']
    end
    
    def cookies
      session['carpool.cookies'] ||={}
    end
    
    private
    
    def attempt_authentication!
      cookies[:referring_domain] = URI.parse(@env['HTTP_REFERRER']).host
      cookies[:redirect_to]      = @env['HTTP_REFERRER']
    end
    
    def valid_referrer?
      !(@env['HTTP_REFERRER'].nil? or @env['HTTP_REFERRER'].blank?)
    end
    
    def valid_request?
      @env['PATH_INFO'] == "/sso/authenticate"
    end
    
  end
end