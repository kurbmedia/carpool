require 'net/http'

module Carpool
  
  class Driver
    
    include Carpool::Mixins::Core
    
    class << self
      
      attr_accessor :site_key
      attr_accessor :unauthorized_uri
      attr_accessor :revoke_uri
      
      def passengers
        @passengers ||= []
      end
      
      def passenger(url, options = {})
        options[:site_key] ||= Carpool.generate_site_key(url)
        options[:secret]   ||= Carpool.generate_site_key(url.reverse)
        passengers << { url => options }
      end
      
      def site_key
        @site_key ||= Carpool.generate_site_key(@env['HTTP_HOST'])
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
      puts carpool_cookies.inspect
      env['carpool'] = Carpool::SessionManager.new(env) unless env['carpool'] && env['carpool'] != Carpool::SessionManager
      
      return @app.call(env) unless valid_request?
      return revoke_all_instances! if is_revoking?
      manager.auth_request!
      
      unless manager.authentication_exists?
        redir = manager.auth_redirect
        return [redir[:status], redir[:action], redir[:message]]
      end
      
      result = catch(:carpool) do
        @app.call(env)
      end
      
      case result
      when Array
        response = result
      when Carpool::Seatbelt        
        response = result.response
      else
        response = result
      end

      return response

    end
    
    private
    
    def valid_request?
      (@env['PATH_INFO'].downcase == "/sso/authenticate" || @env['PATH_INFO'].downcase == "/sso/revoke") && !@env['HTTP_REFERER'].to_s.blank?
    end
    
    def is_revoking?
      @env['PATH_INFO'].downcase == "/sso/revoke"
    end
    
    def revoke_all_instances!
      [307, {"Location" => Carpool.revoke_uri}, "Revoking global access."]
    end
    
  end
end