require 'carpool/mixins/core'
require 'carpool/responder'
require 'carpool/encryptor'
require 'carpool/driver'
require 'carpool/passenger'
require 'carpool/seatbelt'
require 'base64'
require 'fast-aes'

require 'carpool/rails/railtie' if defined?(Rails) && defined?(Rails::Railtie)

module Carpool
  
  class << self
      
    def driver_uri
      "#{Carpool::Passenger.driver_uri}/sso/authenticate"
    end
    
    def revoke_uri
      "#{Carpool::Passenger.driver_uri}/sso/revoke"
    end
    
    def acts_as=(obj); @acts_as = obj.to_sym; end
    def acts_as; @acts_as; end
    def acts_as?(type)
      @acts_as == type.to_sym
    end

  end
    
end