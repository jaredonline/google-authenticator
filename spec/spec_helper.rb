require 'time'
require 'active_record'
require 'action_controller'
require 'rotp'

require 'google-authenticator-rails'

class MockController
  class << self
    attr_accessor :callbacks

    def prepend_before_filter(filter)
      self.callbacks ||= []
      self.callbacks = [filter] + self.callbacks
    end
  end

  include GoogleAuthenticatorRails::ActionController::Integration

  attr_accessor :cookies

  def initialize
    @cookies = MockCookieJar.new
  end
end

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
  :adapter => 'sqlite3',
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

    t.timestamps
  end

  create_table :custom_users, :force => true do |t|
    t.string :mfa_secret
    t.string :email
    t.string :user_name
    t.string :persistence_token

    t.timestamps
  end
end

class BaseUser < ActiveRecord::Base
  attr_accessible :email, :user_name
  self.table_name = "users"

  before_save do |user|
    user.persistence_token ||= "token"
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

class ProcUser < BaseUser
  acts_as_google_authenticated :method => Proc.new { |user| "#{user.user_name}@futureadvisor-admin" }
end

class SymbolUser < BaseUser
  acts_as_google_authenticated :method => :email
end

class StringUser < BaseUser
  acts_as_google_authenticated :method => "email"
end
