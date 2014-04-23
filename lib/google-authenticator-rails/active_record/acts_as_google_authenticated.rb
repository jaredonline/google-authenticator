module GoogleAuthenticatorRails # :nodoc:
  module ActiveRecord # :nodoc:
    module ActsAsGoogleAuthenticated # :nodoc:
      def self.included(base)
        base.extend ClassMethods
      end

      # This is the single integration point.  Monkey patch ActiveRecord::Base
      # to include the ActsAsGoogleAuthenticated module, which allows a user
      # to call User.acts_as_google_authenticated.
      #
      # The model being used must have a string column named "google_secret", or an explicitly
      # named column.
      #
      # Example:
      #
      #   class User
      #     acts_as_google_authenticated
      #   end
      #
      #   @user = user.new
      #   @user.set_google_secret           # => true
      #   @user.google_qr_uri               # => http://path.to.google/qr?with=params
      #   @user.google_authentic?(123456)   # => true
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
      #       "#{user_name}@example.com"
      #     end
      #   end
      #
      #   @user = User.new(:user_name => "ted")
      #   @user.google_label                    # => "ted@example.com"
      #
      #   class User
      #     acts_as_google_authenticated :method => Proc.new { |user| user.user_name_with_label.upcase }
      #
      #     def user_name_with_label
      #       "#{user_name}@example.com"
      #     end
      #   end
      #
      #   @user = User.new(:user_name => "ted")
      #   @user.google_label                    # => "TED@EXAMPLE.COM"
      #
      module ClassMethods # :nodoc

        # Initializes the class attributes with the specified options and includes the
        # respective ActiveRecord helper methods
        #
        # Options:
        #   [:column_name] the name of the column used to create the google_label
        #   [:method] name of the method to call to create the google_label
        #             it supercedes :column_name
        #   [:google_secret_column] the column the secret will be stored in, defaults
        #                           to "google_secret"
        #   [:lookup_token] the column to use to find the record from the DB, defaults
        #                   to "persistence_token"
        #   [:drift] drift the number of seconds that the client and server are
        #            allowed to drift apart. Default value is 6.
        #
        #   [:issuer] the name of the issuer to appear in the app (optional), defaults
        #             to ""
        def acts_as_google_authenticated(options = {})
          @google_label_column  = options[:column_name]           || :email
          @google_label_method  = options[:method]                || :default_google_label_method
          @google_secret_column = options[:google_secret_column]  || :google_secret
          @google_lookup_token  = options[:lookup_token]          || :persistence_token
          @google_drift         = options[:drift]                 || GoogleAuthenticatorRails::DRIFT
          @google_issuer        = options[:issuer]

          puts ":skip_attr_accessible is no longer required.  Called from #{Kernel.caller[0]}}" if options.has_key?(:skip_attr_accessible)

          [:google_label_column, :google_label_method, :google_secret_column, :google_lookup_token, :google_drift, :google_issuer].each do |cattr|
            self.singleton_class.class_eval { attr_reader cattr }
          end

          include GoogleAuthenticatorRails::ActiveRecord::Helpers
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, GoogleAuthenticatorRails::ActiveRecord::ActsAsGoogleAuthenticated)
