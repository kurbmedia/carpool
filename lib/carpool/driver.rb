require 'net/http'

module Carpool
  
  class Driver
    
    include Carpool::Mixins::Core
    
    class << self
  
      attr_accessor :unauthorized_uri
      attr_accessor :revoke_uri
      
      def passengers
        @passengers ||= []
      end
      
      def passenger(url, secret)
        passengers << { :host => url, :secret => secret }
      end
      
    end
    
    def initialize(app)
      @app = app
      Carpool.acts_as = :driver
      yield Carpool::Driver if block_given?
      self
    end
    
    def call(env)
      @env = env      
      
      env['carpool'] = Carpool::Seatbelt.new(env) unless env['carpool'] && env['carpool'] != Carpool::Seatbelt
      return revoke_all_instances! if is_revoking?       

      if valid_request?
        manager.auth_request!
        unless manager.authentication_exists?
          return Carpool::Responder.authenticate
        end
      end      
      
      result = catch(:carpool) do
        @app.call(env)
      end
      
      return result

    end
    
    private
    
    def valid_request?
      (@env['PATH_INFO'].downcase == "/sso/authenticate" || @env['PATH_INFO'].downcase == "/sso/revoke") && !@env['HTTP_REFERER'].to_s.blank?
    end
    
    def is_revoking?
      @env['PATH_INFO'].downcase == "/sso/revoke"
    end
    
    def revoke_all_instances!
      [307, {"Location" => Carpool::Driver.revoke_uri}, "Revoking global access."]
    end
    
  end
end