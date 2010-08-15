require 'net/http'

module Carpool
  
  class Driver
    
    class << self
      
      attr_accessor :site_key
      attr_accessor :unauthorized_uri
      
      def passengers
        @passengers ||= []
      end
      
      def passenger(url, options = {})
        options[:site_key] ||= Carpool.generate_site_key(url)
        passengers << { url => options }
      end
      
      def site_key
        @site_key ||= Carpool.generate_site_key(@env['HTTP_HOST'])
      end
      
    end
    
    def initialize(app)
      @app = app
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
      unless Carpool::Driver.passengers.collect{ |p| p.keys.first.downcase }.include?(referrer.host)   
        return [500, {}, 'Unauthorized request.']
      end
      
      # Attempt to find an existing driver session.
      # If one is found, redirect back to the passenger site and include our seatbelt
      # The seatbelt includes two parts:
      #   1) The referring uri, so that Carpool::Passenger on the other end can send the user back to their location one authenticated
      #   2) The session payload. This is an AES encrypted hash of whatever attributes you've made available. The encrypted hash is
      #      keyed with the site_key and secret of the referring site for extra security.
      #
      unless cookies[:passenger_token]
        
        puts "Carpool::Driver: Redirecting to authentication path.."
        Carpool.auth_attempt = true
        cookies[:redirect_to] = referrer
        response = [301, {'Location' => Carpool::Driver.unauthorized_uri}, 'Redirecting unauthorized user...']
        
      else
        
        puts "Carpool::Driver: Redirecting to passenger site.."
        seatbelt = Carpool.generate_seatbelt(@env['HTTP_REFERER'], cookies[:passenger_token])
        
        new_uri  = "#{referrer.protocol}://"
        new_uri << referrer.host
        new_uri << (referrer.port) ? ":#{referrer.port}" : ""
        new_uri << "/sso/authorize?seatbelt=#{seatbelt}"
        
        response = [301, {'Location' => new_uri}, 'Approved!']
                
      end
      
      response
      
    end
        
    def session
      @env['rack.session']
    end
    
    def cookies
      session['carpool.cookies'] ||= {}
    end
    
    private
    
    def valid_referrer?
      !(@env['HTTP_REFERER'].nil? or @env['HTTP_REFERER'].blank?)
    end
    
    def valid_request?
      @env['PATH_INFO'].downcase == "/sso/authenticate"
    end
    
  end
end