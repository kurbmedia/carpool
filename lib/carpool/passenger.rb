require 'net/http'

module Carpool
  class Passenger
    
    def initialize(app)
      @app = app
      self
    end
    
    def call(env)
      @env = env
      cookies[:scope] = "passenger"
      return @app.call(env) unless valid_request? && valid_referrer?
    end
    
    def session
      @env['rack.session']
    end
    
    def cookies
      session['carpool.cookies'] ||={}
    end
    
    private
    
    def valid_request?
      @env['PATH_INFO'] == "/sso/verify" || @env['PATH_INFO'] == "/sso/authorize"
    end
    
    def valid_referrer?
      
    end
    
  end
end