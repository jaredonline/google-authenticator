require "google-authenticator-rails/version"
require 'active_support'
require 'active_record'
require 'openssl'
require 'rotp'
require 'google-qr'

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
    def uses_google_authenticator(options = {})
      attr_accessible :google_secret
      @google_label_column = options[:column_name]  || :email
      @google_label_method = options[:method]       || Proc.new { |user| user.__send__(instance_variable_get("@google_label_column")) }
      
      define_method(:google_authenticate) do |code|
        Google::Authenticator::Rails.valid?(code, self.google_secret)
      end
      
      define_method(:set_google_secret!) do
        update_attributes(google_secret: Google::Authenticator::Rails::generate_secret)
      end
      
      define_method(:google_qr_uri) do
        GoogleQR.new(data: ROTP::TOTP.new(google_secret).provisioning_uri(google_label), size: "200x200").to_s
      end
      
      define_method(:google_label) do
        method = self.class.instance_variable_get("@google_label_method")
        case method
          when Proc
            method.call(self)
          when Symbol, String
            self.__send__(method)
        end
      end
    end
  end
end
