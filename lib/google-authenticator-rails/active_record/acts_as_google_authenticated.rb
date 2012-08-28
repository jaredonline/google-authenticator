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
      # 
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