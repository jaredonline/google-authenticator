require 'spec_helper'

describe GoogleAuthenticatorRails::ActionController::RailsAdapter do
  describe '#cookies' do
    let(:controller)  { MockController.new }
    let(:adapter)     { GoogleAuthenticatorRails::ActionController::RailsAdapter.new(controller) }

    after   { adapter.cookies }
    specify { controller.should_receive(:cookies) }
  end
end