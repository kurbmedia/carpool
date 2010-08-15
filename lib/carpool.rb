require 'carpool/driver'
require 'carpool/passenger'
require 'fast-aes'
require 'base64'

module Carpool
  
  class << self
    
    def current_scope
      env['carpool.cookies'][:scope]
    end
    
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
  
  def self.generate_token(keys)
    self.generate_site_key(keys)
  end
  
  def self.generate_seatbelt(redirection, seatbelt)
    CGI.escape(Base64.encode64({ :redirect_to => redirection, :seatbelt => seatbelt }).gsub( /\s/, ''))
  end
  
  def self.unpack_key(key)
    Base64.decode64(key)
  end
    
end