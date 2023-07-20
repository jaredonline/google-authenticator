module GoogleAuthenticatorRails
  module ActionController
    class RailsAdapter
      class LoadedTooLateError < StandardError
        def initialize
          super("GoogleAuthenticatorRails is trying to prepend a before_filter in ActionController::Base.  Because you've already defined" +
          " ApplicationController, your controllers will not get this before_filter.  Please load GoogleAuthenticatorRails before defining" +
          " ApplicationController.")
        end
      end

      def initialize(controller)
        @controller = controller
      end

      def cookies
        @controller.send(:cookies)
      end
    end

    module Integration
      def self.included(klass)
        if klass.descendants.map(&:name).include?("ApplicationController")
          raise RailsAdapter::LoadedTooLateError.new
        end

        method = klass.respond_to?(:prepend_before_action) ? :prepend_before_action : :prepend_before_filter
        klass.send(method, :activate_google_authenticator_rails)
      end

      private
      def activate_google_authenticator_rails
        GoogleAuthenticatorRails::Session::Base.controller = RailsAdapter.new(self)
      end
    end
  end
end

ActiveSupport.on_load(:action_controller) do
  if defined?(ActionController::Base)
    ActionController::Base.send(:include, GoogleAuthenticatorRails::ActionController::Integration)
  end
  
  if defined?(ActionController::API)
    ActionController::API.send(:include, GoogleAuthenticatorRails::ActionController::Integration)
  end
end
