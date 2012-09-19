require 'spec_helper'

describe GoogleAuthenticatorRails::Session::Base do
  let(:controller)  { MockController.new }
  let(:user)        { User.create(:password => "password", :email => "email@example.com") }

  # Instantiate the controller so it activates UserSession
  before { controller }

  describe 'ClassMethods' do
    describe '#find' do
      context 'no session' do
        specify { UserMfaSession.find.should be false }
      end

      context 'session' do
        before  { set_cookie_for(user) }
        after   { clear_cookie }
        subject { UserMfaSession.find }

        it            { should be_a UserMfaSession }
        its(:record)  { should eq user }
      end
    end

    describe '#create' do
      after   { clear_cookie }
      subject { UserMfaSession.create(user) }

      it            { should be_a UserMfaSession }
      its(:record)  { should eq user }
    end
  end
end

def set_cookie_for(user)
  controller.cookies[UserMfaSession.__send__(:cookie_key)] = { :value => [user.persistence_token, user.id].join('::'), :expires => nil }
end

def clear_cookie
  controller.cookies[UserMfaSession.__send__(:cookie_key)] = nil
end