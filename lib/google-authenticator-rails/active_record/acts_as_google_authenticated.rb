module ActiveRecord
  module ActsAsGoogleAuthenticated
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def acts_as_google_authenticated(options = {})
        attr_accessible :google_secret
        @google_label_column = options[:column_name]  || :email
        @google_label_method = options[:method]       || :default_google_label_method

        [:google_label_column, :google_label_method].each do |cattr|
          self.class.__send__(:define_method, cattr) do
            instance_variable_get("@#{cattr}")
          end
        end

        include ActiveRecord::GoogleAuthentication
      end
    end
  end
end