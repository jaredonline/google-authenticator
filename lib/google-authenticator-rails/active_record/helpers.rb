module GoogleAuthenticatorRails # :nodoc:
  module ActiveRecord  # :nodoc:
    module Helpers
      def set_google_secret
        self.__send__("#{self.class.google_secret_column}=", GoogleAuthenticatorRails::generate_secret)
        save
      end

      def google_authentic?(code,drift=nil)
        drift = self.class.google_drift if drift.nil?
        GoogleAuthenticatorRails.valid?(code, google_secret_value, drift)
      end

      def google_qr_uri(w=200,h=200)
        GoogleQR.new(:data => ROTP::TOTP.new(google_secret_value, :issuer => google_issuer).provisioning_uri(google_label.to_s), :size => "#{w}x#{h}").to_s
      end

      def qr_code_png(size=200,level=:h)
       qrcode = RQRCode::QRCode.new(ROTP::TOTP.new(google_secret_value, :issuer => google_issuer).provisioning_uri(google_label.to_s), :level => level.to_sym)
       qrcode.as_png(:size => size)
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
