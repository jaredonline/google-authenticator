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
    self.class.callbacks.each { |callback| self.__send__(callback) }
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
    t.timestamps
  end
end

class User < ActiveRecord::Base
  attr_accessible :email, :user_name
  
  acts_as_google_authenticated

  before_save do |user|
    user.persistence_token ||= "token"
  end
end

class CustomUser < ActiveRecord::Base
  attr_accessible :email, :user_name

  acts_as_google_authenticated :google_secret_column => :mfa_secret
end

class NilMethodUser < ActiveRecord::Base
  set_table_name "users"

  acts_as_google_authenticated :method => true
end