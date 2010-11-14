require 'net/http'

module Carpool
  
  class Driver
    
    include Carpool::Mixins::Core
    
    class << self
      
      attr_accessor :site_key
      attr_accessor :unauthorized_uri
      attr_accessor :revoke_uri
      
      def passengers
        @passengers ||= []
      end
      
      def passenger(url, options = {})
        options[:site_key] ||= Carpool.generate_site_key(url)
        options[:secret]   ||= Carpool.generate_site_key(url.reverse)
        passengers << { url => options }
      end
      
      def site_key
        @site_key ||= Carpool.generate_site_key(@env['HTTP_HOST'])
      end
      
    end
    
    def initialize(app)
      @app = app
      Carpool.acts_as = :driver
      yield Carpool::Driver if block_given?
      self
    end
    
    def call(env)
      
      @env = env
      carpool_cookies['scope'] = "driver"
      puts session.inspect

      # Unless we are trying to authenticate a passenger, just continue through the stack.
      return @app.call(env) unless valid_request? && valid_referrer? 

      # Parse the referring site
      referrer = URI.parse(@env['HTTP_REFERER'])
      
      # Unless this domain is listed as a potential passenger, issue a 500.
      current_passenger = Carpool::Driver.passengers.reject{ |p| !p.keys.first.downcase.include?(referrer.host) }
      if current_passenger.nil? or current_passenger.empty?
        return [500, {'Content-Type'=>'text/plain'}, 'Unauthorized request.']
      end
      
      # We are logging out this user, clear out our cookies and reset the session, then pass the request to the normal revoke path.
      if is_revoking?
        destroy_session!
        set_new_path(Carpool::Driver.revoke_uri)
        return @app.call(env)
      end
      
      carpool_cookies['current_passenger'] = current_passenger.first[referrer.host.to_s]
      
      # Attempt to find an existing driver session.
      # If one is found, redirect back to the passenger site and include our seatbelt
      # The seatbelt includes two parts:
      #   1) The referring uri, so that Carpool::Passenger on the other end can send the user back to their location one authenticated
      #   2) The session payload. This is an AES encrypted hash of whatever attributes you've made available. The encrypted hash is
      #      keyed with the site_key and secret of the referring site for extra security.
      #
      unless carpool_passenger_token.nil?
        seatbelt = SeatBelt.new(env)
        seatbelt.set_referrer(referrer)
        Carpool.auth_attempt  = false
        cleanup_session!
        return Carpool.redirect_request(seatbelt.create_payload!, 'Approved!')
      end
      
      Carpool.auth_attempt = true
      carpool_cookies['redirect_to'] = referrer
      
      set_new_path(Carpool::Driver.unauthorized_uri)
      return @app.call(env)
      
    end
    
    private
    
    def valid_referrer?
      !(@env['HTTP_REFERER'].nil? or @env['HTTP_REFERER'].blank?)
    end
    
    def valid_request?
      @env['PATH_INFO'].downcase == "/sso/authenticate" || @env['PATH_INFO'].downcase == "/sso/revoke"
    end
    
    def is_revoking?
      @env['PATH_INFO'].downcase == "/sso/revoke"
    end
    
  end
end