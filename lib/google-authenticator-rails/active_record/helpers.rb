module GoogleAuthenticatorRails # :nodoc:
  module ActiveRecord  # :nodoc:
    module Helpers
      def set_google_secret
        self.__send__("#{self.class.google_secret_column}=", GoogleAuthenticatorRails::generate_secret)
        save
      end

      def google_authentic?(code)
        GoogleAuthenticatorRails.valid?(code, google_secret_value, self.class.google_drift)
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

      private
      def default_google_label_method
        self.__send__(self.class.google_label_column)
      end

      def google_secret_value
        self.__send__(self.class.google_secret_column)
      end

      def google_issuer
        self.class.google_issuer
      end
    end
  end
end
