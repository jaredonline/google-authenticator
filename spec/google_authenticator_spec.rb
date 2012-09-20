require 'spec_helper'

describe GoogleAuthenticatorRails do
  let(:random32) { "5qlcip7azyjuwm36" }
  before do
    ROTP::Base32.stub!(:random_base32).and_return(random32)
  end
  
  it 'implements counter based passwords' do
    GoogleAuthenticatorRails::generate_password("test", 1).should == 812658
    GoogleAuthenticatorRails::generate_password("test", 2).should == 73348
  end
  
  it 'implements time based password' do
    time = Time.parse("2012-08-07 11:11:11 AM +0700")
    Time.stub!(:now).and_return(time)
    GoogleAuthenticatorRails::time_based_password("test").should == 472374
  end
  
  it 'can validate a code' do
    time = Time.parse("2012-08-07 11:11:11 AM +0700")
    Time.stub!(:now).and_return(time)
    GoogleAuthenticatorRails::valid?(472374, "test").should be_true
  end
  
  it 'can create a secret' do
    GoogleAuthenticatorRails::generate_secret.should == random32
  end
  
  context 'integration with ActiveRecord'  do
    
    before do
      time = Time.parse("2012-08-07 11:11:00 AM +0700")
      Time.stub!(:now).and_return(time)
      @user = User.create(:email => "test@example.com", :user_name => "test_user")
      @user.google_secret = "test"
    end
    
    it 'validates codes' do
      @user.google_authenticate(472374).should be_true
    end
    
    it 'validates with 5 seconds of drift' do
      time = Time.parse("2012-08-07 11:11:34 AM +0700")
      Time.stub!(:now).and_return(time)
      @user.google_authenticate(472374).should be_true
    end
    
    it 'does not validate with 6 seconds of drift' do
      time = Time.parse("2012-08-07 11:11:36 AM +0700")
      Time.stub!(:now).and_return(time)
      @user.google_authenticate(472374).should be_false
    end
    
    it 'creates a secret' do
      @user.set_google_secret
      @user.google_secret.should == random32
    end
    
    context 'skip_attr_accessible' do
      it 'respects the :skip_attr_accessible flag' do
        User.should_not_receive(:attr_accessible).with(:google_secret)
        User.acts_as_google_authenticated :skip_attr_accessible => true
      end

      it 'respects the default' do
        User.should_receive(:attr_accessible).with(:google_secret)
        User.acts_as_google_authenticated
      end
    end

    context 'secret column' do
      before do
        GoogleAuthenticatorRails.stub!(:generate_secret).and_return("test")
        @user = CustomUser.create(:email => "test@example.com", :user_name => "test_user")
        @user.set_google_secret
      end

      it 'validates code' do
        @user.google_authenticate(472374).should be_true
      end

      it 'generates a url for a qr code' do
        @user.google_qr_uri.should == "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest%40example.com%3Fsecret%3Dtest&chs=200x200"
      end
    end

    context 'google label' do
      let(:user)  { NilMethodUser.create(:email => "test@example.com", :user_name => "test_user") }
      subject     { lambda { user.google_label } }
      it          { should raise_error(NoMethodError) }
    end

    context 'qr codes' do
      
      it 'generates a url for a qr code' do
        @user.set_google_secret
        @user.google_qr_uri.should == "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest%40example.com%3Fsecret%3D5qlcip7azyjuwm36&chs=200x200"
      end
      
      it 'can generate off any column' do
        @user.class.acts_as_google_authenticated :column_name => :user_name
        @user.set_google_secret
        @user.google_qr_uri.should == "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest_user%3Fsecret%3D5qlcip7azyjuwm36&chs=200x200"
      end
      
      it 'can generate with a custom proc' do
        @user.class.acts_as_google_authenticated :method => Proc.new { |user| "#{user.user_name}@futureadvisor-admin" }
        @user.set_google_secret
        @user.google_qr_uri.should == "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest_user%40futureadvisor-admin%3Fsecret%3D5qlcip7azyjuwm36&chs=200x200"
      end
      
      it 'can generate with a method symbol' do
        @user.class.acts_as_google_authenticated :method => :email
        @user.set_google_secret
        @user.google_qr_uri.should == "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest%40example.com%3Fsecret%3D5qlcip7azyjuwm36&chs=200x200"
      end
      
      it 'can generate with a method string' do
        @user.class.acts_as_google_authenticated :method => "email"
        @user.set_google_secret
        @user.google_qr_uri.should == "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest%40example.com%3Fsecret%3D5qlcip7azyjuwm36&chs=200x200"
      end
      
    end
    
  end
  
end