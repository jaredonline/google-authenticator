require "google-authenticator-rails/version"
require 'active_support'
require 'active_record'
require 'openssl'
require 'rotp'

module Google
  module Authenticator
    module Rails   
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

class ActiveRecord::Base
  class << self
    def uses_google_authenticator
      attr_accessible :google_secret
            
      define_method(:google_authenticate) do |code|
        Google::Authenticator::Rails.valid?(code, self.google_secret)
      end
      
      define_method(:set_google_secret!) do
        update_attributes(google_secret: Google::Authenticator::Rails::generate_secret)
      end
    end
  end
end
