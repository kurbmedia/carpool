require 'fast-aes'
require 'yaml'

module Carpool
  class SeatBelt
    
    include Carpool::Mixins::Core
    
    attr_accessor :env
    attr_accessor :redirect_uri
    attr_accessor :user
    
    # SeatBelt instances require access to the rack environment.
    def initialize(env)
      @env = env
    end
    
    # 'Attaches' the current user into the session so it can be re-authenticated when
    # a passenger requests it at a later date. We 'fasten' the users seatbelt for the trip back to the
    # referring site.
    # Fasten! returns a url for redirection back to our passenger site including the seatbelt used for authentication
    # on the other end.
    #
    def fasten!(user)
      cookies[:passenger_token] = generate_token(user)
      Carpool.auth_attempt = false
      payload = create_payload!
      cookies[:redirect_to] = nil
      payload
    end
    
    # Restore the user from our payload. We 'remove' their seatbelt because they have arrived!
    def remove!
      payload  = @env['X-CARPOOL-PAYLOAD']
      payload  = payload.flatten.first if payload.is_a?(Array) # TODO: Figure out why our header is an array?
      seatbelt = YAML.load(Base64.decode64(CGI.unescape(payload))).to_hash
      puts "Seatbelt: #{seatbelt.inspect}"
      user     = Base64.decode64(seatbelt[:user])
      key      = Carpool.generate_site_key(@env['SERVER_NAME'])
      secret   = Carpool::Passenger.secret
      digest   = Digest::SHA256.new
      digest.update("#{key}--#{secret}")
      aes  = FastAES.new(digest.digest)
      data = aes.decrypt(user)
      @redirect_uri = seatbelt[:redirect_uri].to_s
      @user         = YAML.load(data).to_hash
      self
    end
    
    # Create a redirection payload to be sent back to our passenger
    def create_payload!
      seatbelt = self.to_s
      referrer = cookies[:redirect_to]
      driver   = Digest::SHA256.new
      driver   = driver.update(cookies[:current_passenger][:secret]).to_s
      new_uri  = "#{referrer.scheme}://"
      new_uri << referrer.host
      new_uri << ((referrer.port != 80 && referrer.port != 443) ? ":#{referrer.port}" : "")
      new_uri << "/sso/authorize?seatbelt=#{seatbelt}&driver=#{driver}"
    end
    
    def to_s
      CGI.escape(Base64.encode64({:redirect_uri => cookies[:redirect_to].to_s, :user => cookies[:passenger_token] }.to_yaml.to_s).gsub( /\s/, ''))
    end
    
    private
    
    def generate_token(user)
      referrer  = cookies[:redirect_to]
      passenger = Carpool::Driver.passengers.reject{ |p| p.keys.first.downcase != referrer.host }.first.values.first
            
      digest    = Digest::SHA256.new
      digest.update("#{passenger[:site_key]}--#{passenger[:secret]}")
      aes = FastAES.new(digest.digest)
      Base64.encode64(aes.encrypt(user.encrypted_credentials.to_yaml.to_s)).gsub( /\s/, '')
      
    end
        
  end
end