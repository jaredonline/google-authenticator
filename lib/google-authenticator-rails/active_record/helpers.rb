module GoogleAuthenticatorRails # :nodoc:
  mattr_accessor :secret_encryptor
  module ActiveRecord  # :nodoc:
    module Helpers
      def set_google_secret
        change_google_secret_to!(GoogleAuthenticatorRails::generate_secret)
      end

      def google_authentic?(code)
        GoogleAuthenticatorRails.valid?(code, google_secret_value_plain, self.class.google_drift)
      end

      def google_qr_uri(size = nil)
        GoogleQR.new(:data => ROTP::TOTP.new(google_secret_value, :issuer => google_issuer).provisioning_uri(google_label), :size => size || self.class.google_qr_size).to_s
      end

      def google_label
        method = self.class.google_label_method
        case method
          when Proc
            method.call(self)
          when Symbol, String
            self.__send__(method)
          else
            raise NoMethodError.new("the method used to generate the google_label was never defined")
        end
      end

      def google_token_value
        self.__send__(self.class.google_lookup_token)
      end
      
      def encrypt_google_secret!
        change_google_secret_to!(google_secret_value)
      end

      private
      def default_google_label_method
        self.__send__(self.class.google_label_column)
      end
      
      def google_secret_value
        self.__send__(self.class.google_secret_column)
      end

      def google_secret_value_plain
        google_secret = google_secret_value
        google_secret && self.class.google_secrets_encrypted ? google_secret_encryptor.decrypt_and_verify(google_secret) : google_secret
      end
      
      def change_google_secret_to!(secret, encrypt = self.class.google_secrets_encrypted)
        secret = google_secret_encryptor.encrypt_and_sign(secret) if encrypt
        self.__send__("#{self.class.google_secret_column}=", secret)
        save!
      end

      def google_issuer
        self.class.google_issuer
      end
      
      def google_secret_encryptor
        GoogleAuthenticatorRails.secret_encryptor ||= GoogleAuthenticatorRails::ActiveRecord::Helpers.get_google_secret_encryptor
      end
      
      def self.get_google_secret_encryptor
        ActiveSupport::MessageEncryptor.new(Rails.application.key_generator.generate_key('Google-secret encryption key', 32))
      end
    end
  end
end
