module ActiveRecord # :nodoc:
  module GoogleAuthentication # :nodoc:
    def set_google_secret!
      update_attributes("#{self.class.google_secret_column}" => Google::Authenticator::Rails::generate_secret)
    end

    def google_authenticate(code)
      Google::Authenticator::Rails.valid?(code, google_secret_value)
    end

    def google_qr_uri
      GoogleQR.new(data: ROTP::TOTP.new(google_secret_value).provisioning_uri(google_label), size: "200x200").to_s
    end

    def google_label
      method = self.class.google_label_method
      case method
        when Proc
          method.call(self)
        when Symbol, String
          self.__send__(method)
      end
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