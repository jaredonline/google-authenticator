# GoogleAuthenticatorRails

[![Gem Version](https://badge.fury.io/rb/google-authenticator-rails.png)](http://badge.fury.io/rb/google-authenticator-rails)
[![Build Status](https://secure.travis-ci.org/jaredonline/google-authenticator.png)](http://travis-ci.org/jaredonline/google-authenticator)
[![Code Climate](https://codeclimate.com/github/jaredonline/google-authenticator.png)](https://codeclimate.com/github/jaredonline/google-authenticator)

Rails (ActiveRecord) integration with the Google Authenticator apps for Android and the iPhone.  Uses the Authlogic style for cookie management.

## Installation

Add this line to your application's Gemfile:

    gem 'google-authenticator-rails'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install google-authenticator-rails

## Usage

Example:

```ruby
class User
acts_as_google_authenticated
end

@user = User.new
@user.set_google_secret           # => true
@user.google_qr_uri               # => http://path.to.google/qr?with=params
@user.google_authentic?(123456) # => true
```

Google Labels
When setting up an account with the GoogleAuthenticator you need to provide
a label for that account (to distinguish it from other accounts).

GoogleAuthenticatorRails allows you to customize how the record will create
that label.  There are three options:
  - The default just uses the column "email" on the model
  - You can specify a custom column with the :column_name option
  - You can specify a custom method via a symbol or a proc

Examples:

```ruby
class User
	acts_as_google_authenticated :column => :user_name
end

@user = User.new(:user_name => "ted")
@user.google_label                      # => "ted"

class User
	acts_as_google_authenticated :method => :user_name_with_label

	def user_name_with_label
	  "#{user_name}@example.com"
	end
end

@user = User.new(:user_name => "ted")
@user.google_label                    # => "ted@example.com"

class User
	acts_as_google_authenticated :method => Proc.new { |user| user.user_name_with_label.upcase }

	def user_name_with_label
	  "#{user_name}@example.com"
	end
end

@user = User.new(:user_name => "ted")
@user.google_label                    # => "TED@EXAMPLE.COM"
```

You can also specify a column for storing the google secret.  The default is `google_secret`.

Example

```ruby
class User
	acts_as_google_authenticated :google_secret_column => :mfa_secret
end

@user = User.new
@user.set_google_secret
@user.mfa_secret 		 # => "56ahi483"
```

You can also specify which column the appropriate `MfaSession` subclass should use to look up the record:

Example

```ruby
class User
  acts_as_google_authenticated :lookup_token => :salt
end
```

The above will cause the `UserMfaSession` class to call `User.where(:salt => cookie_salt)` or `User.scoped(:conditions => { :salt => cookie_salt })` to find the appropriate record.

## Sample Rails Setup

This is a very rough outline of how GoogleAuthenticatorRails is meant to manage the sessions and cookies for a Rails app.

```ruby
Gemfile

gem 'rails'
gem 'google-authenticator-rails'
```

First add a field to your user model to hold the Google token.
```ruby
class AddGoogleSecretToUser < ActiveRecord::Migration
  def change
    add_column :users, :google_secret, :string
  end
end
```

```ruby
app/models/users.rb

class User < ActiveRecord::Base
  acts_as_google_authenticated
end
```

If you want to authenticate based on a model called `User`, then you should name your session object `UserMfaSession`.

```ruby
app/models/user_mfa_session.rb

class UserMfaSession <  GoogleAuthenticatorRails::Session::Base
  # no real code needed here
end
```

```ruby
app/controllers/user_mfa_session_controller.rb

class UserMfaSessionController < ApplicationController
  
  def new
    # load your view
  end

  def create
    user = current_user # grab your currently logged in user
    if user.google_authentic?(params[:mfa_code])
      UserMfaSession.create(user)
      redirect_to root_path
    else
      flash[:error] = "Wrong code"
      render :new
    end
  end

end
```

```ruby
app/controllers/application_controller.rb

class ApplicationController < ActionController::Base
  before_filter :check_mfa

  private
  def check_mfa
     if !(user_mfa_session = UserMfaSession.find) && (user_mfa_session ? user_mfa_session.record == current_user : !user_mfa_session)
      redirect_to new_user_mfa_session_path
    end
  end
end
```

By default, the cookie related to the MfaSession expires in 24 hours, but this can be changed:
```ruby
config/initializers/google_authenticator_rails.rb

GoogleAuthenticatorRails.time_until_expiration = 1.month
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

MIT.
