require 'fast-aes'
require 'yaml'

module Carpool
  class SeatBelt
    
    include Carpool::Mixins::Core
    
    attr_accessor :_response
        
    # SeatBelt instances require access to the rack environment.
    def initialize(env)
      @env = env
      self
    end
    
    # 'Attaches' the current user into the session so it can be re-authenticated when
    # a passenger requests it at a later date. We 'fasten' the users seatbelt for the trip back to the
    # referring site.
    # Fasten! returns a url for redirection back to our passenger site including the seatbelt used for authentication
    # on the other end.
    #
    def fasten!
      
      seatbelt  = self.to_s
      passenger = stringify_keys([manager.passenger_for_auth.values].flatten.first)
      puts passenger.inspect
      referrer  = manager.current_passenger 
      
      driver   = Digest::SHA256.new
      driver   = driver.update(passenger['secret']).to_s
      new_uri  = "#{referrer.scheme}://"
      new_uri << referrer.host
      new_uri << ((referrer.port != 80 && referrer.port != 443) ? ":#{referrer.port}" : "")
      new_uri << "/sso/authorize?seatbelt=#{seatbelt}&driver=#{driver}"
      
      cleanup_session!
      
      @_response = [307, {"Location" => new_uri}, "Redirect to passenger."]      
      
    end
    
    # Restore the user from our payload. We 'remove' their seatbelt because they have arrived!
    def remove!
      payload  = @env['X-CARPOOL-PAYLOAD']
      payload  = payload.flatten.first if payload.is_a?(Array) # TODO: Figure out why our header is an array?
      seatbelt = YAML.load(Base64.decode64(CGI.unescape(payload))).to_hash
      seatbelt = stringify_keys(seatbelt)
      user     = Base64.decode64(seatbelt['user'])
      key      = Carpool.generate_site_key(@env['SERVER_NAME'])
      secret   = Carpool::Passenger.secret
      digest   = Digest::SHA256.new
      digest.update("#{key}--#{secret}")
      aes  = FastAES.new(digest.digest)
      data = aes.decrypt(user)
      @redirect_uri = seatbelt['redirect_uri'].to_s
      @user         = YAML.load(data).to_hash
      self
    end
    
    def to_s
      CGI.escape(Base64.encode64({'redirect_uri' => manager.current_passenger.to_s, 'user' => carpool_cookies['passenger_token'] }.to_yaml.to_s).gsub( /\s/, ''))
    end
    
    def reject!
      @_response = [500, {}, "Invalid passenger."]
    end
    
    def response
      @_response ||= [500, {}, "Invalid request."]
      @_response[1].reverse_merge!({'Cache-Control'  => 'private, no-cache, max-age=0, must-revalidate', "Content-Type" => 'text/plain'})
      @_response
    end
    
    private
    
    def stringify_keys(hash)
      hash.inject({}) do |options, (key, value)|
        options[key.to_s] = value
        options
      end
    end
        
  end
end