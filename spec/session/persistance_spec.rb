require 'spec_helper'

describe GoogleAuthenticatorRails::Session::Base do
  let(:controller)  { MockController.new }
  let(:user)        { User.create(:password => "password", :email => "email@example.com") }

  # Instantiate the controller so it activates UserSession
  before { controller.send(:activate_google_authenticator_rails) }

  describe 'ClassMethods' do
    describe '::find' do
      subject { UserMfaSession.find }

      context 'no session' do
        it { should be nil }
      end

      context 'session' do
        before  { set_cookie_for(user) }
        after   { clear_cookie }

        it            { should be_a UserMfaSession }
        its(:record)  { should eq user }
      end
    end

    describe '::create' do
      after   { clear_cookie }
      subject { UserMfaSession.create(user) }

      it            { should be_a UserMfaSession }
      its(:record)  { should eq user }

      context 'nil user' do
        let(:user)  { nil }
        subject     { lambda { UserMfaSession.create(user) } }
        it          { should raise_error(GoogleAuthenticatorRails::Session::Persistence::TokenNotFound) }
      end
    end
  end

  describe 'InstanceMethods' do
    describe '#valid?' do
      subject { UserMfaSession.create(user) }
      context 'user object' do
        it { should be_valid }
      end
    end
  end
end

def set_cookie_for(user)
  controller.cookies[UserMfaSession.__send__(:cookie_key)] = { :value => [user.persistence_token, user.id].join('::'), :expires => nil }
end

def clear_cookie
  controller.cookies[UserMfaSession.__send__(:cookie_key)] = nil
end