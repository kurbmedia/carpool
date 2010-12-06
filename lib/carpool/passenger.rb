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
      
      return @app.call(env) unless valid_reference? && valid_referrer?
      return [500, {}, 'Invalid seatbelt.'] if request.params['seatbelt'].nil? or request.params['seatbelt'].blank?
      
      result = catch(:carpool) do
        @app.call(env)
      end
      
      case result
      when Array
        response = result
      when Carpool::Seatbelt        
        response = result.response
      else
        response = result
      end

      return response
      
    end
    
    private
    
    def valid_request?
      @env['PATH_INFO'] == "/sso/authorize" || @env['PATH_INFO'] == "/sso/remote_authentication"
    end
    
    def valid_reference?    
      referring_uri = request.params['driver'].to_s
      secret_match  = Digest::SHA256.new
      secret_match  = secret_match.update(Carpool::Passenger.secret).to_s
      referring_uri = referring_uri.to_s.gsub(/(\[|\]|\")/,'') # TODO: Figure out why ruby 1.9.2 has extra chars.
      secret_match  = secret_match.to_s
      referring_uri == secret_match
    end
    
  end
end