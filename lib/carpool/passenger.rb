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
      Carpool.acts_as = :passenger
      yield Carpool::Passenger if block_given?
      self
    end
    
    def call(env)
      @env = env
      @params = CGI.parse(env['QUERY_STRING'])
      cookies[:scope] = "passenger"
      
      # If this isn't an authorize request from the driver, just ignore it.
      return @app.call(env) unless valid_request? && valid_referrer?
      
      # If we can't find our payload, then we need to abort.      
      return [500, {}, 'Invalid seatbelt.'] if @params['seatbelt'].nil? or @params['seatbelt'].blank?
      
      # Set a custom HTTP header for our payload and send the request to the user's /sso/authorize handler.
      env['X-CARPOOL-PAYLOAD'] = @params['seatbelt']
      return @app.call(env)
      
    end
    
    private
    
    def valid_request?
      @env['PATH_INFO'] == "/sso/authorize"
    end
    
    def valid_referrer?
      return false if @env['HTTP_REFERER'].nil? or @env['HTTP_REFERER'].blank?
      return false if @params['driver'].nil?    or @params['driver'].blank?
      
      referring_uri = @params['driver'].to_s
      secret_match  = Digest::SHA256.new
      secret_match  = secret_match.update(Carpool::Passenger.secret).digest.to_s
      puts "Trying to match #{referring_uri} to #{secret_match} : #{referring_uri == secret_match}"
      referring_uri === secret_match
    end
    
  end
end