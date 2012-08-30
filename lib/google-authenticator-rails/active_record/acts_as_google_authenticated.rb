module ActiveRecord # :nodoc:
  module ActsAsGoogleAuthenticated # :nodoc:
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods # :nodoc

      # Initializes the class attributes with the specified options and includes the 
      # GoogleAuthentication module
      # 
      # Options:
      #   [:column_name] the name of the column used to create the google_label
      #   [:method] name of the method to call to created the google_label
      #             it supercedes :column_name
      #   [:google_secret_column] the column the secret will be stored in, defaults
      #                           to "google_secret"
      #   [:skip_attr_accessible] defaults to false, if set to true will no call
      #                           attr_accessible on the google_secret_column
      def acts_as_google_authenticated(options = {})
        @google_label_column  = options[:column_name]           || :email
        @google_label_method  = options[:method]                || :default_google_label_method
        @google_secret_column = options[:google_secret_column]  || :google_secret
        
        attr_accessible @google_secret_column unless options[:skip_attr_accessible] == true

        [:google_label_column, :google_label_method, :google_secret_column].each do |cattr|
          self.class.__send__(:define_method, cattr) do
            instance_variable_get("@#{cattr}")
          end
        end

        include ActiveRecord::GoogleAuthentication
      end
    end
  end
end