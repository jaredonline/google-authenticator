require 'spec_helper'

describe GoogleAuthenticatorRails::Session::Base do
  describe 'ClassMethods' do
    it 'sets the conroller in a thread-safe way' do
      GoogleAuthenticatorRails::Session::Base.controller = nil

      thread1 = Thread.new do
        controller = MockController.new
        GoogleAuthenticatorRails::Session::Base.controller = controller
        GoogleAuthenticatorRails::Session::Base.controller.should eq controller
      end
      thread1.join

      thread2 = Thread.new do
        controller = MockController.new
        GoogleAuthenticatorRails::Session::Base.controller = controller
        GoogleAuthenticatorRails::Session::Base.controller.should eq controller
      end
      thread2.join

      GoogleAuthenticatorRails::Session::Base.controller.should be_nil
    end

    describe '#activated?' do
      subject { GoogleAuthenticatorRails::Session::Base }

      context 'true' do
        before  { GoogleAuthenticatorRails::Session::Base.controller = MockController.new }

        its(:activated?) { should be true }
      end

      context 'false' do
        before  { GoogleAuthenticatorRails::Session::Base.controller = nil }

        its(:activated?) { should be false }
      end
    end
  end

  describe 'InstanceMethods' do
    describe '#initialize' do
      context 'controller missing' do
        before  { GoogleAuthenticatorRails::Session::Base.controller = nil }
        specify { lambda { GoogleAuthenticatorRails::Session::Base.new(nil) }.should raise_error(GoogleAuthenticatorRails::Session::Activation::ControllerMissingError) }
      end
    end
  end
end