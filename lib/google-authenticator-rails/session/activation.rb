module GoogleAuthenticatorRails
  module Session
    module Activation
      class ControllerMissingError < StandardError; end

      def self.included(klass)
        klass.class_eval do 
          extend  ClassMethods
          include InstanceMethods
        end
      end

    end

    module ClassMethods
      # Every thread in Passenger handles only a single request at a time, but there can be many threads running.  
      # This ensures that when setting the current active controller
      # it only gets set for the current active thread (and doesn't mess up any other threads).
      # 
      def controller=(controller)
        Thread.current[:google_authenticator_rails_controller] = controller
      end

      def controller
        Thread.current[:google_authenticator_rails_controller]
      end

      # If the controller isn't set, we can't use the Sessions.  They rely on the session information passed
      # in from ActionController to access the cookies.
      # 
      def activated?
        !controller.nil?
      end
    end

    module InstanceMethods
      attr_reader :record

      def initialize(record)
        raise Activation::ControllerMissingError unless self.class.activated?

        @record = record
      end

      private
      def controller
        self.class.controller
      end
    end
  end
end