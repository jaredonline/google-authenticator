module GoogleAuthenticatorRails
  module Session
    module Persistence
      class TokenNotFound < StandardError; end

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
          token, user_id = parse_cookie(cookie).values_at(:token, :user_id)
          conditions = { :salt => token, :id => user_id }
          record = __send__(finder, conditions).first
          session = new(record)
          session.valid? ? session : nil
        else
          nil
        end
      end

      def create(user)
        raise GoogleAuthenticatorRails::Session::Persistence::TokenNotFound if !user.respond_to?(:salt) || user.salt.blank?
        controller.cookies[cookie_key] = create_cookie(user.salt, user.id)
        new(user)
      end

      private
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
        @_klass ||= "#{self.to_s.sub("MfaSession", "")}".constantize
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