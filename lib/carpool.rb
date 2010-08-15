require 'carpool/mixins'
require 'carpool/driver'
require 'carpool/passenger'
require 'carpool/seatbelt'
require 'base64'

module Carpool
  
  class << self
    
    def auth_attempt=(bool)
      @auth_attempt = bool
    end
    
    def auth_attempt?
      @auth_attempt ||= false
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