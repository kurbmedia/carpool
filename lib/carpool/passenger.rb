require 'net/http'

module Carpool
  class Passenger
    
    include Carpool::Mixins::Core
    
    class << self
      
      attr_accessor :driver_uri
      attr_accessor :secret
            
    end
    
    def initialize(app)
      @app = app
      yield Carpool::Passenger if block_given?
      self
    end
    
    def call(env)
      @env = env
      cookies[:scope] = "passenger"
      
      # If this isn't an authorize request from the driver, just ignore it.
      return @app.call(env) unless valid_request? && valid_referrer?
      
      # If we can't find our payload, then we need to abort.
      params = CGI.parse(env['QUERY_STRING'])
      return [500, {}, 'Invalid seatbelt.'] if params['seatbelt'].nil? or params['seatbelt'].blank?
      
      # Set a custom HTTP header for our payload and send the request to the user's /sso/authorize handler.
      env['X-CARPOOL-PAYLOAD'] = params['seatbelt']
      return @app.call(env)
      
    end
    
    private
    
    def valid_request?
      @env['PATH_INFO'] == "/sso/authorize"
    end
    
    def valid_referrer?
      return false if @env['HTTP_REFERER'].nil? or @env['HTTP_REFERER'].blank?
      true
      # TODO: Figure out referers don't always work right when coming from redirect_to in rails.
      # referring_uri = URI.parse(@env['HTTP_REFERER'])
      #       driver_uri    = URI.parse(Carpool::Passenger.driver_uri)
      #       puts "Trying to match #{referring_uri} to #{driver_uri}"
      #       referring_uri.host.to_s.downcase === driver_uri.host.to_s.downcase
    end
    
  end
end