require 'fast-aes'
module Carpool
  class Encryptor
    
    def self.generate_token(user_hash, token)
      digest  = self.create_digest(token)
      aes     = FastAES.new(digest.digest)  
      encoded = self.encode(user_hash)
      self.encode64(aes.encrypt(encoded))
    end
    
    def self.generate_payload(redirection, user_token)
      self.encode64(Marshal.dump({:redirect_to => redirection, :user => user_token}))
    end
    
    def self.process_seatbelt(seatbelt)
      seatbelt = Marshal.load(Base64.decode64(seatbelt))
      {
        :redirect_to => seatbelt[:redirect_to],
        :user        => self.recover_user(seatbelt[:user])
      }
    end
    
    private
    
    def self.create_digest(data)
      digest = Digest::SHA256.new
      digest.update(data)
    end
    
    def self.encode(data)
      object = Marshal.dump(data)
      self.encode64(object)
    end
    
    def self.encode64(data)
      Base64.encode64(data).gsub(/\s/, '')
    end
    
    def self.decode(data)
      object = Base64.decode64(data)
      Marshal.load(object)
    end
      
    def self.recover_user(user_token)
      digest = self.create_digest(Carpool::Passenger.secret)
      aes = FastAES.new(digest.digest)
      self.decode(aes.decrypt(Base64.decode64(user_token)))
    end
    
  end
end