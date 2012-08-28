# Sets up some basic accessors for use with the ROTP module
# 
module Google
  module Authenticator # :nodoc:
    module Rails # :nodoc:
      # Drift is set to 6 because ROTP drift is not inclusive.  This allows a drift of 5 seconds.
      DRIFT = 6
       
      def self.generate_password(secret, iteration)
        ROTP::HOTP.new(secret).at(iteration)
      end
    
      def self.time_based_password(secret)
        ROTP::TOTP.new(secret).now
      end
    
      def self.valid?(code, secret)
        ROTP::TOTP.new(secret).verify_with_drift(code, DRIFT)
      end
      
      def self.generate_secret
        ROTP::Base32.random_base32
      end
    end
  end
end