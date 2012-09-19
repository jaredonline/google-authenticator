module GoogleAuthenticatorRails
  module ActionController
    class RailsAdapter
      class LoadedTooLateError < StandardError; end

      def initialize(controller)
        @controller = controller
      end

      def cookies
        @controller.cookies
      end
    end

    module Integration
      def self.included(klass)
        raise RailsAdapter::LoadedTooLateError.new("GoogleAuthenticatorRails is trying to prepend a before_filter in ActionController::Base to active itself" +
              ", the problem is that ApplicationController has already been loaded meaning the before_filter won't get copied into your" +
              " application. Generally this is due to another gem or plugin requiring your ApplicationController prematurely, such as" +
              " the resource_controller plugin. The solution is to require GoogleAuthenticatorRails before these other gems / plugins. Please require" +
              " GoogleAuthenticatorRails first to get rid of this error.") if defined?(::ApplicationController)

        klass.prepend_before_filter(:activate_google_authenticator_rails)
      end

      private
      def activate_google_authenticator_rails
        GoogleAuthenticatorRails::Session::Base.controller = RailsAdapter.new(self)
      end
    end
  end
end

ActionController::Base.send(:include, GoogleAuthenticatorRails::ActionController::Integration)
