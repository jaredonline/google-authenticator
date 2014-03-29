module GoogleAuthenticatorRails
  module Session
    module Persistence
      class TokenNotFound < StandardError; end

      class << self
        def find_classes=(x)
          @find_classes = Hash[ x.map { |kv| kv.map(&:to_s) } ]
        end

        def find_classes
          @find_classes ||= {}
        end
      end

      def self.included(klass)
        klass.class_eval do
          extend  ClassMethods
          include InstanceMethods
        end
      end
    end

    module ClassMethods

      def find
        cookie = controller.cookies[cookie_key]
        if cookie
          token, user_id = parse_cookie(cookie).values_at(:token, column_name)
          conditions = { klass.google_lookup_token => token, :id => user_id }
          record = __send__(finder, conditions).first
          session = new(record)
          session.valid? ? session : nil
        else
          nil
        end
      end

      def create(user)
        raise GoogleAuthenticatorRails::Session::Persistence::TokenNotFound if user.nil? || !user.respond_to?(user.class.google_lookup_token) || user.google_token_value.blank?
        controller.cookies[cookie_key] = create_cookie(user.google_token_value, user.id)
        new(user)
      end

      private
      def column_name
        "#{klass}_id".downcase.to_sym
      end

      def finder
        @_finder ||= klass.public_methods.include?(:where) ? :rails_3_finder : :rails_2_finder
      end

      def rails_3_finder(conditions)
        klass.where(conditions)
      end

      def rails_2_finder(conditions)
        klass.scoped(:conditions => conditions)
      end

      def klass
        @_klass ||= find_klass
      end

      def find_klass
        "#{self.to_s.sub("MfaSession", "")}".constantize
      rescue NameError
        ::GoogleAuthenticatorRails::Session::Persistence.find_classes[self.to_s].constantize
      end

      def parse_cookie(cookie)
        token, user_id = cookie.split('::')
        { :token => token, :user_id => user_id }
      end

      def create_cookie(token, user_id)
        value = [token, user_id].join('::')
        {
          :value    => value,
          :expires  => GoogleAuthenticatorRails.time_until_expiration.from_now
        }
      end

      def cookie_key
        "#{klass.to_s.downcase}_mfa_credentials"
      end
    end

    module InstanceMethods
      def valid?
        !record.nil?
      end
    end
  end
end
