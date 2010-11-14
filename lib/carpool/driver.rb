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
      cookies[:scope]    = "driver"

      # Unless we are trying to authenticate a passenger, just continue through the stack.
      return @app.call(env) unless valid_request? && valid_referrer? 

      # Parse the referring site
      referrer = URI.parse(@env['HTTP_REFERER'])
      
      # Unless this domain is listed as a potential passenger, issue a 500.
      current_passenger = Carpool::Driver.passengers.reject{ |p| !p.keys.first.downcase.include?(referrer.host) }
      if current_passenger.nil? or current_passenger.empty?
        return [500, {}, 'Unauthorized request.']
      end
      
      # We are logging out this user, clear out our cookies and reset the session.
      if is_revoking?
        session.delete('carpool.cookies')
        response = [302, {'Location' => Carpool::Driver.revoke_uri}, 'Redirecting logged out session...']
        return response
      end
      
      cookies[:current_passenger] = current_passenger.first[referrer.host.to_s]
      
      # Attempt to find an existing driver session.
      # If one is found, redirect back to the passenger site and include our seatbelt
      # The seatbelt includes two parts:
      #   1) The referring uri, so that Carpool::Passenger on the other end can send the user back to their location one authenticated
      #   2) The session payload. This is an AES encrypted hash of whatever attributes you've made available. The encrypted hash is
      #      keyed with the site_key and secret of the referring site for extra security.
      #
      unless cookies[:passenger_token]
        
        requested_with = env['HTTP_X_REQUESTED_WITH'].to_s
        
        unless requested_with.eql?("CarpoolRemoteAuthRequest") || requested_with.downcase.eql?("xmlhttprequest")
          puts "Carpool::Driver: Redirecting to authentication path.."
          Carpool.auth_attempt = true
          cookies[:redirect_to] = referrer        
          response = [302, {'Location' => Carpool::Driver.unauthorized_uri}, 'Redirecting unauthorized user...']
        else
          # If we are using AJAX to process this request, return false for login as we cannot simply
          # redirect the request.
          response = [200, {'Content-Type' => 'text/plain'}, 'unauthorized']
        end
        
      else
        
        puts "Carpool::Driver: Redirecting to passenger site.."
        cookies[:redirect_to] = referrer
        seatbelt = SeatBelt.new(env).create_payload!

        response = [302, {'Location' => seatbelt}, 'Approved!']
        Carpool.auth_attempt  = false
        cookies[:redirect_to] = false
        cookies[:current_passenger] = nil
                
      end
      
      response
      
    end
    
    private
    
    def valid_referrer?
      puts "Referrer?: #{@env['HTTP_REFERER']}"
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