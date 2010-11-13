# carpool

Carpool is a single-sign-on (sso) solution for rack based applications. It is designed to allow you to designate one application as a "driver" which powers authentication, and sends session information to "passengers". It has been tested with both Rails 2.3 and Rails 3 (as rack middleware).

Carpool handles securely transferring user information across domains (using AES encryption), as well as redirection so that already-signed-in users will have a seamless experience. It is designed to be as unobtrusive as possible, allowing you to handle the actual login and session maintenance in any manner you would like.

# Installation

Install the gem
		gem install carpool
	
# Configuration

Configure the application you wish to designate as your driver. In Rails based applications, add Carpool::Driver to your middleware stack. The configuration takes three options.

- One or more passengers. This takes two options, first, the domain name of the passenger application (the referrer), second a 'secret' designated to the passenger application. This secret can be anything, but must match in both the driver and passenger sites.
- unauthorized_uri. If there isn't an existing session within the driver application, redirect to this location to handle logins etc
- revoke_uri. This url is used to "logout" passengers from the driver

In environment.rb:

		Rails.configuration.middleware.use Carpool::Driver do |config|
		  config.passenger 'apasengerdomain.com', :secret => 'secret_key'
		  config.unauthorized_uri = 'urlforunauthoried.passengers'
		  config.revoke_uri       = 'signout'
		end

Then configure the application that you would like to function as your passenger, adding Carpool::Passenger to your middleware stack. This takes two options.

- driver_uri. This is the url/location of the 'driver' site. (ie: http://yourdriver.com)
- secret. This is a shared secret between both the driver and the passenger to verify the passenger has permission to authenticate itself here.

		Rails.configuration.middleware.use Carpool::Passenger do |config|
		  config.driver_uri = 'http://yourdriver.com'
		  config.secret = "secret_key"
		end
	
# Authenticating

### Driver Application

Authentication in your driver application can be handled however you would like. When sessions are created, simply check to see if authentication was requested by a passenger website, or the actual application itself. To check this, use Carpool.auth_attempt?  When authentication is initiated by a passenger, Carpool creates a 'seatbelt' object which represents the session details to be passed back after successful login/session.

		# Create user session (authlogic format used as an example)	
		user_session.save
	
		if Carpool.auth_attempt?
	
		  # This login request was generated from a passenger.
		  # current_user represents our now logged in user.
		  # env is the rack environment.
	
		  seatbelt = Carpool::SeatBelt.new(env).fasten!(current_user)	# Fasten yer seatbelt to be taken back to the requesting app.
		  redirect_to seatbelt	# Redirect back to the passenger site (to /sso/authorize)
	
		else
		  # Handle local logins here
		end

Seatbelt.fasten! generates a url representing a url back to the Passenger application, including a session payload that Carpool::Passenger uses to generate a session within itself.	

### Passenger Application

Passengers only need to be able to handle two aspects of the process, redirecting `/login` and handing the resulting seatbelt from your Driver application.

**Redirecting login:** To use the Driver application for logins, redirect users to Carpool.driver_uri

**Processing the Seatbelt:** On successful login the Drier will redirect the user back to `/sso/authorize` within the passenger application. On redirect, the header `X-CARPOOL-PAYLOAD`, and the parameters `seatbelt` and `driver` will be set. To be sure authentication has taken place, check for the `X-CARPOOL-PAYLOAD` header, then process the seatbelt.
	
		# Remove our seatbelt because we've arrived! (ok really just process the result)
		seatbelt = Carpool::SeatBelt.new(request.env).remove!
	
		# User will contain any parameters encrypted via the Driver (see above).
		user = seatbelt.user     
	
		# Handle your session however using the user hash.
		# Call the redirect_uri from our seatbelt to return users back to their original requesting url.
		redirect_to seatbelt.redirect_uri

**Rails users:** make sure you setup a route to respond to `/sso/authorize`.

## User Data

To make Carpool actually useful in your passenger applications, you would likely need to pass data from the Driver to the Passenger. The `Carpool::Seatbelt.fasten!` method takes one parameter, which can be any Ruby class that responds to the method `encrypted_credentials`. This method should return a hash containing any information you would like to access in your Passengers. This hash is then encrypted via AES using 
Nate Wiger's [FastAES](https://github.com/nateware/fast-aes) gem. Although this data is encrypted, it is not recommended that the user data hash include sensitive data such as credit card numbers, social security numbers etc. 

		class User
		  def encrypted_credentials
		    {
			 :first_name => 'My', 
		     :last_name => 'Name', 
		     :id => id_for_database_use 
	 		}
		  end
		end


### Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

### Copyright

Copyright (c) 2010 Brent Kirby / Kurb Media LLC. See LICENSE for details.
