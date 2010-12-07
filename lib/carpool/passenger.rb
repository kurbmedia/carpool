module Carpool
  class Passenger
    
    include Carpool::Mixins::Core
    
    class << self
      
      attr_accessor :driver_uri
      attr_accessor :secret
            
    end
    
    def initialize(app)
      @app = app
      Carpool.acts_as = :passenger
      yield Carpool::Passenger if block_given?
      self
    end
    
    def call(env)
      @env = env
      
      env['carpool'] = Carpool::Seatbelt.new(env) unless env['carpool'] && env['carpool'] != Carpool::Seatbelt
      
      return @app.call(env) unless valid_request?
      result = catch(:carpool) do
        @app.call(env)
      end
      return result
      
    end
    
    private
    
    def valid_request?
      @env['PATH_INFO'] == "/sso/authorize"
    end
    
  end
end