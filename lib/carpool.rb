require 'carpool/mixins/core'
require 'carpool/driver'
require 'carpool/passenger'
require 'carpool/seatbelt'
require 'carpool/session_manager'
require 'base64'

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
  
  def self.generate_site_key(url)
    digest = Digest::SHA256.new
    digest.update(url)
    Base64.encode64(digest.digest).gsub( /\s/, '')
  end
  
  def self.unpack_key(key)
    Base64.decode64(key)
  end
    
end