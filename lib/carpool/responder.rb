module Carpool
  
  class Responder
    
    def self.authenticate
      [307, {"Location" => Carpool::Driver.unauthorized_uri}, "Redirecing for authentication."]
    end
    
    def self.passenger_redirect(passenger, payload)
      new_uri  = "#{passenger.scheme}://"
      new_uri << passenger.host
      new_uri << ((passenger.port != 80 && passenger.port != 443) ? ":#{passenger.port}" : "")
      new_uri << "/sso/authorize?seatbelt=#{payload}"
      [303, {"Location" => new_uri}, "Redirecting...."]
    end
    
  end
  
end