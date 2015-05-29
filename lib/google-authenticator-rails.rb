# Stuff the gem requires
#
require 'active_support'
require 'active_record'
require 'openssl'
require 'rotp'
require 'google-qr'

# Stuff the gem is
#
GOOGLE_AUTHENTICATOR_RAILS_PATH = File.dirname(__FILE__) + "/google-authenticator-rails/"

[
  "version",

  "action_controller",
  "active_record",
  "session"
].each do |library|
   require GOOGLE_AUTHENTICATOR_RAILS_PATH + library
 end

# Sets up some basic accessors for use with the ROTP module
#
module GoogleAuthenticatorRails
  # Drift is set to 6 because ROTP drift is not inclusive. This allows a drift of 5 seconds.
  DRIFT = 6

  # How long a Session::Persistence cookie should last.
  @@time_until_expiration = 24.hours

  # Last part of a Session::Persistence cookie's key
  @@cookie_key_suffix = nil

  # Additional configuration passed to a Session::Persistence cookie.
  @@cookie_options = { :httponly => true }

  def self.generate_password(secret, iteration)
    ROTP::HOTP.new(secret).at(iteration)
  end

  def self.time_based_password(secret)
    ROTP::TOTP.new(secret).now
  end

  def self.valid?(code, secret, drift = DRIFT)
    ROTP::TOTP.new(secret).verify_with_drift(code, drift)
  end

  def self.generate_secret
    ROTP::Base32.random_base32
  end

  def self.time_until_expiration
    @@time_until_expiration
  end

  def self.time_until_expiration=(time_until_expiration)
    @@time_until_expiration = time_until_expiration
  end

  def self.cookie_key_suffix
    @@cookie_key_suffix
  end

  def self.cookie_key_suffix=(suffix)
    @@cookie_key_suffix = suffix
  end

  def self.cookie_options
    @@cookie_options
  end

  def self.cookie_options=(options)
    @@cookie_options = options
  end
end
