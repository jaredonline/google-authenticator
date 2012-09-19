require 'spec_helper'

describe GoogleAuthenticatorRails::ActionController::Integration do
  describe '.included' do
    it 'should raise if not included fast enough' do
      class ApplicationController < MockController; end
      lambda { MockController.send(:include, GoogleAuthenticatorRails::ActionController::Integration) }.should raise_error(GoogleAuthenticatorRails::ActionController::RailsAdapter::LoadedTooLateError)
      Object.send(:remove_const, :ApplicationController)
    end

    it 'should add the before filter' do
      MockController.should_receive(:prepend_before_filter).with(:activate_google_authenticator_rails)
      MockController.send(:include, GoogleAuthenticatorRails::ActionController::Integration)
    end
  end

  describe '#activate_google_authenticator_rails' do
    before  { MockController.send(:include, GoogleAuthenticatorRails::ActionController::Integration) }
    
    specify do 
      controller = MockController.new
      controller.send(:activate_google_authenticator_rails)
      GoogleAuthenticatorRails::Session::Base.controller.should be_a  GoogleAuthenticatorRails::ActionController::RailsAdapter
    end
  end
end