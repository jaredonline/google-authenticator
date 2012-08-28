require 'google-authenticator-rails/active_record/google_authentication'
require 'google-authenticator-rails/active_record/acts_as_google_authenticated'

class ActiveRecord::Base # :nodoc:
  
  # This is the single integration point.  Monkey patch ActiveRecord::Base
  # to include the ActsAsGoogleAuthenticated module, which allows a user 
  # to call User.acts_as_google_authenticated.
  # 
  # Example:
  # 
  #   class User
  #     acts_as_google_authenticated
  #   end
  # 
  #   @user = user.new
  #   @user.set_google_secret!          # => true
  #   @user.google_qr_uri               # => http://path.to.google/qr?with=params
  #   @user.google_authenticate(123456) # => true
  # 
  # Google Labels
  # When setting up an account with the GoogleAuthenticator you need to provide
  # a label for that account (to distinguish it from other accounts).
  # 
  # GoogleAuthenticatorRails allows you to customize how the record will create
  # that label.  There are three options:
  #   - The default just uses the column "email" on the model
  #   - You can specify a custom column with the :column_name option
  #   - You can specify a custom method via a symbol or a proc
  # 
  # Examples:
  # 
  #   class User
  #     acts_as_google_authenticated :column => :user_name
  #   end
  # 
  #   @user = User.new(:user_name => "ted")
  #   @user.google_label                      # => "ted"
  # 
  #   class User
  #     acts_as_google_authenticated :method => :user_name_with_label
  # 
  #     def user_name_with_label
  #       "#{user_name}@mysweetservice.com"
  #     end
  #   end
  # 
  #   @user = User.new(:user_name => "ted")
  #   @user.google_label                    # => "ted@mysweetservice.com"
  # 
  #   class User
  #     acts_as_google_authenticated :method => Proc.new { |user| user.user_name_with_label.upcase }
  #     
  #     def user_name_with_label
  #       "#{user_name}@mysweetservice.com"
  #     end
  #   end
  #   
  #   @user = User.new(:user_name => "ted")
  #   @user.google_label                    # => "TED@MYSWEETSERVICE.COM"
  # 
  include ActiveRecord::ActsAsGoogleAuthenticated
end