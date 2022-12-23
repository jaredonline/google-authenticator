ENV['RAILS_ENV'] = 'test'

require 'time'
require 'rails'
require 'active_record'
require 'action_controller'
require 'rotp'
require 'bundler'
require 'bundler/setup'

require 'simplecov'
SimpleCov.start

require 'google-authenticator-rails'

module MockControllerBase
  def self.included(klass)
    klass.class_eval do
      extend ClassMethods

      include GoogleAuthenticatorRails::ActionController::Integration

      attr_accessor :cookies
    end
  end

  module ClassMethods
    attr_accessor :callbacks

    def prepend_before_filter(filter)
      self.callbacks ||= []
      self.callbacks = [filter] + self.callbacks
    end
  end

  def initialize
    @cookies = MockCookieJar.new
  end
end

class MockController
  include MockControllerBase
end

class MockControllerWithApplicationController
  include MockControllerBase
end

# Simulate Rails' autoloading for ApplicationController.
autoload :ApplicationController, File.join(File.dirname(__FILE__), 'support/application_controller')

class MockCookieJar < Hash
  def [](key)
    hash = super
    hash && hash[:value]
  end

  def cookie_domain
    nil
  end

  def delete(key, options = {})
    super(key)
  end
end

class UserMfaSession < GoogleAuthenticatorRails::Session::Base; end

ActiveRecord::Base.establish_connection(
  :adapter  => 'sqlite3',
  :database => ':memory:'
)

ActiveRecord::Schema.define do
  self.verbose = false

  create_table :users, :force => true do |t|
    t.string :google_secret
    t.string :email
    t.string :user_name
    t.string :password
    t.string :persistence_token
    t.string :salt

    t.timestamps
  end

  create_table :custom_users, :force => true do |t|
    t.string :mfa_secret
    t.string :email
    t.string :user_name
    t.string :persistence_token
    t.string :salt

    t.timestamps
  end
end

class BaseUser < ActiveRecord::Base
  # Older versions of ActiveRecord allow attr_accessible, but newer
  # ones do not
  begin
    attr_accessible :email, :user_name, :password
  rescue
    attr_accessor :email, :user_name, :password
  end

  self.table_name = "users"

  before_save do |user|
    user.persistence_token ||= "token"
    user.salt              ||= "salt"
  end
end

class User < BaseUser
  acts_as_google_authenticated
end

class CustomUser < BaseUser
  self.table_name = "custom_users"
  acts_as_google_authenticated :google_secret_column => :mfa_secret
end

class NilMethodUser < BaseUser
  acts_as_google_authenticated :method => true
end

class ColumnNameUser < BaseUser
  acts_as_google_authenticated :column_name => :user_name
end

class DriftUser < BaseUser
  acts_as_google_authenticated :drift => 31
end

class ProcLabelUser < BaseUser
  acts_as_google_authenticated :method => Proc.new { |user| "#{user.user_name}@futureadvisor-admin" }
end

class ProcIssuerUser < BaseUser
  acts_as_google_authenticated :issuer => Proc.new { |user| user.admin? ? "FA Admin" :  "FutureAdvisor" }
  def admin?
    true
  end
end

class SymbolUser < BaseUser
  acts_as_google_authenticated :method => :email
end

class StringUser < BaseUser
  acts_as_google_authenticated :method => "email"
end

class SaltUserMfaSession < GoogleAuthenticatorRails::Session::Base; end

class SaltUser < BaseUser
  acts_as_google_authenticated :lookup_token => :salt
end

class QrCodeUser < BaseUser
  acts_as_google_authenticated :qr_size => '300x300', :method => :email
end

class EncryptedUser < BaseUser
  acts_as_google_authenticated :encrypt_secrets => true
end

class EncryptedCustomUser < BaseUser
  self.table_name = 'custom_users'
  acts_as_google_authenticated :encrypt_secrets => true, :google_secret_column => :mfa_secret
end

class UserFactory
  def self.create(klass)
    klass.create(:email => 'test@example.com', :user_name => 'test_user')
  end
end

class RailsApplication < Rails::Application
end if defined?(Rails)
