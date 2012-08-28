require 'google-authenticator-rails/active_record/google_authentication'
require 'google-authenticator-rails/active_record/acts_as_google_authenticated'

class ActiveRecord::Base
  include ActiveRecord::ActsAsGoogleAuthenticated
end