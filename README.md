Ï# Google::Authenticator

[![Build Status](https://secure.travis-ci.org/jaredonline/google-authenticator.png)](http://travis-ci.org/jaredonline/google-authenticator)

Rails (ActiveRecord) integration with the Google Authenticator apps for Android and the iPhone.

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
@user.set_google_secret!          # => true
@user.google_qr_uri               # => http://path.to.google/qr?with=params
@user.google_authenticate(123456) # => true
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
@user.set_google_secret!
@user.mfa_secret 		 # => "56ahi483"
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

MIT.