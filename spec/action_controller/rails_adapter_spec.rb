require 'spec_helper'

describe GoogleAuthenticatorRails::ActionController::RailsAdapter do
  describe '#cookies' do
    it 'should call cookies on the underlying controller' do
      controller  = MockController.new
      adapter     = GoogleAuthenticatorRails::ActionController::RailsAdapter.new(controller)

      controller.should_receive(:cookies)
      adapter.cookies
    end
  end
end