require 'google-authenticator-rails'
require 'time'
require 'active_record'
require 'rotp'

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
    t.timestamps
  end
end