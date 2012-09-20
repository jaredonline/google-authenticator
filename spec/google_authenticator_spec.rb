require 'spec_helper'

describe GoogleAuthenticatorRails do
  let(:random32) { "5qlcip7azyjuwm36" }
  before do
    ROTP::Base32.stub!(:random_base32).and_return(random32)
  end
  
  describe '#generate_password' do
    subject { GoogleAuthenticatorRails::generate_password("test", counter) }
    
    context 'counter = 1' do
      let(:counter) { 1 }
      it { should == 812658 }
    end

    context 'counter = 2' do
      let(:counter) { 2 }
      it { should == 73348 }
    end
  end
  
  context 'time-based passwords' do
    let(:time)    { Time.parse("2012-08-07 11:11:11 AM +0700") }
    let(:secret)  { "test" }
    let(:code)    { 472374 }
    before        { Time.stub!(:now).and_return(time) }

    specify { GoogleAuthenticatorRails::time_based_password(secret).should == code }
    specify { GoogleAuthenticatorRails::valid?(code, secret).should be true } 

    specify { GoogleAuthenticatorRails::valid?(code * 2, secret).should be false }
    specify { GoogleAuthenticatorRails::valid?(code, secret * 2).should be false } 
  end
  
  it 'can create a secret' do
    GoogleAuthenticatorRails::generate_secret.should == random32
  end
  
  context 'integration with ActiveRecord'  do
    let(:original_time) { Time.parse("2012-08-07 11:11:00 AM +0700") }
    let(:time)          { original_time }
    before do
      Time.stub!(:now).and_return(time)
      @user = User.create(:email => "test@example.com", :user_name => "test_user")
      @user.google_secret = "test"
    end
    
    context 'code validation' do
      subject { @user.google_authentic?(472374) }

      it { should be true }

      context 'within 5 seconds of drift' do
        let(:time)  { original_time + 34.seconds }
        it          { should be true }
      end

      context '6 seconds of drift' do
        let(:time)  { original_time + 36.seconds }
        it          { should be false }
      end
    end
    
    it 'creates a secret' do
      @user.set_google_secret
      @user.google_secret.should == random32
    end

    context 'secret column' do
      before do
        GoogleAuthenticatorRails.stub!(:generate_secret).and_return("test")
        @user = CustomUser.create(:email => "test@example.com", :user_name => "test_user")
        @user.set_google_secret
      end

      it 'validates code' do
        @user.google_authentic?(472374).should be_true
      end

      it 'generates a url for a qr code' do
        @user.google_qr_uri.should == "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest%40example.com%3Fsecret%3Dtest&chs=200x200"
      end
    end

    context 'google label' do
      let(:user)    { NilMethodUser.create(:email => "test@example.com", :user_name => "test_user") }
      subject       { lambda { user.google_label } }
      it            { should raise_error(NoMethodError) }
    end

    context 'qr codes' do
      let(:options) { { :email => "test@example.com", :user_name => "test_user" } }
      let(:user)  { User.create options }
      before      { user.set_google_secret }
      subject     { user.google_qr_uri }

      it { should eq "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest%40example.com%3Fsecret%3D5qlcip7azyjuwm36&chs=200x200" }
      
      context 'custom column name' do
        let(:user) { ColumnNameUser.create options }
        it { should eq "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest_user%3Fsecret%3D5qlcip7azyjuwm36&chs=200x200" }
      end
      
      context 'custom proc' do
        let(:user) { ProcUser.create options }
        it { should eq "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest_user%40futureadvisor-admin%3Fsecret%3D5qlcip7azyjuwm36&chs=200x200" }
      end

      context 'method defined by symbol' do
        let(:user) { SymbolUser.create options }
        it { should eq "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest%40example.com%3Fsecret%3D5qlcip7azyjuwm36&chs=200x200" }
      end

      context 'method defined by string' do 
        let(:user) { StringUser.create options }
        it { should eq "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest%40example.com%3Fsecret%3D5qlcip7azyjuwm36&chs=200x200" }
      end      
    end
    
  end
  
end