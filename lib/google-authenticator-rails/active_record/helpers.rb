module GoogleAuthenticatorRails # :nodoc:
  module ActiveRecord  # :nodoc:
    module Helpers
      def set_google_secret
        self.__send__("#{self.class.google_secret_column}=", GoogleAuthenticatorRails::generate_secret)
        save
      end

      # TODO: Remove this method in version 0.0.4
      def set_google_secret!
        put "DEPRECATION WARNING: #set_google_secret! is no longer being used, use #set_google_secret instead. #set_google_secret! will be removed in 0.0.4. Called from #{Kernel.caller[0]}"
        set_google_secret
      end

      def google_authentic?(code)
        GoogleAuthenticatorRails.valid?(code, google_secret_value)
      end

      # TODO: Remove this method in version 0.0.4
      def google_authenticate(code)
        put "DEPRECATION WARNING: #google_authenticate is no longer being used, use #google_authentic? instead. #google_authenticate will be removed in 0.0.4. Called from #{Kernel.caller[0]}"
        google_authentic?(code)
      end

      def google_qr_uri
        GoogleQR.new(:data => ROTP::TOTP.new(google_secret_value).provisioning_uri(google_label), :size => "200x200").to_s
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
    end
  end
end
