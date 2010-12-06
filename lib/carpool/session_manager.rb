module Carpool
  class SessionManager
    
    include Carpool::Mixins::Core
    attr_accessor :env, :current_passenger
    
    def initialize(env)
      @env = env
    end
    
    def authentication_exists?
      carpool_cookies['passenger_token'] && !carpool_cookies['passenger_token'].to_s.blank?
    end
    
    def authenticate!
      throw(:carpool, auth_redirect) unless authentication_exists?
    end
    
    def authorize!(user = null)
      unless Carpool.acts_as?(:passenger)
        return false unless auth_request?
        carpool_cookies['passenger_token'] = generate_token(user)            
        throw(:carpool, seatbelt.fasten!)
      else
        throw(:carpool, seatbelt.remove!)
      end
    end
    
    def auth_redirect
      {:status => 307, :action => {"Location" => Carpool::Driver.unauthorized_uri}, :message => 'Redirect to authentication path for driver.'}
    end
    
    def auth_request!
      return if auth_request?
      carpool_cookies['passenger_uri'] = @env['HTTP_REFERER']
      carpool_cookies['requesting_authentication'] = true
    end
    
    def auth_request?
      carpool_cookies['requesting_authentication'] && carpool_cookies['requesting_authentication'] == true
    end
    
    def current_passenger
      URI.parse(carpool_cookies['passenger_uri'])
    end
    
    def seatbelt
      @_seatbelt ||= Carpool::SeatBelt.new(@env)
    end
      
    def passenger_for_auth
      passenger = Carpool::Driver.passengers.detect{ |p| p.keys.first.downcase.include?(current_passenger.host.downcase) }
      throw(:carpool, seatbelt.reject!) and return if current_passenger.nil?
      puts passenger.inspect
      passenger
    end
    
    def revoke!
      carpool_cookies.delete('passenger_token')
      cleanup_session!
    end
    
    def user
      seatbelt.remove!
      seatbelt.user
    end
    
    private
    
    def generate_token(user)  
      passenger = passenger_for_auth    
      digest    = Digest::SHA256.new
      digest.update("#{passenger[:site_key]}--#{passenger[:secret]}")
      aes = FastAES.new(digest.digest)
      Base64.encode64(aes.encrypt(gather_credentials(user).to_yaml.to_s)).gsub( /\s/, '')      
    end
    
    def gather_credentials(user)
      user.encrypted_credentials
    end
    
  end  
end