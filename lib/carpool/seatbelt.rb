module Carpool
  class Seatbelt
    
    include Carpool::Mixins::Core
    
    attr_accessor :env, :current_passenger, :current_user, :redirect_to
    
    def initialize(env)
      @env = env
    end
    
    def authentication_exists?
      !carpool_passenger_tokens.empty?
    end
    
    def authenticate!
      throw(:carpool, Carpool::Responder.authenticate) unless authentication_exists?
    end
    
    def authorize!(user = nil)
      unless Carpool.acts_as?(:passenger)
        return false unless auth_request?
        update_authentication!(passenger_for_auth[:secret])
        token   = Carpool::Encryptor.generate_token(user.encrypted_credentials, passenger_for_auth[:secret])
        payload = Carpool::Encryptor.generate_payload(current_passenger, token)        
        throw(:carpool, Carpool::Responder.passenger_redirect(current_passenger, payload))        
      else
        seatbelt = Carpool::Encryptor.process_seatbelt(request.params['seatbelt'])
        throw(:carpool, Carpool::Responder.invalid) and return unless seatbelt[:user].is_a?(Hash)
        @current_user = seatbelt[:user]
        @redirect_to  = seatbelt[:redirect_to]
      end
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
    
    def revoke!
      destroy_session!
    end
    
    def success!
      throw(:carpool, [303, {"Location" => @redirect_to.to_s}, "Authorized!"])
    end
    
    private
    
    def passenger_for_auth
      passenger = Carpool::Driver.passengers.detect{ |p| p[:host].downcase.include?(current_passenger.host.downcase) }
      throw(:carpool, Carpool::Responder.invalid) and return if current_passenger.nil?
      puts passenger.inspect
      passenger
    end

  end  
end