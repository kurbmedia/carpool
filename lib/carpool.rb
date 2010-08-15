require 'carpool/driver'
require 'carpool/passenger'
require 'fast-aes'
require 'base64'

module Carpool
  
  class << self
    
    def configuration
      @configuration ||= {}
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