require 'spec_helper'

class User < ActiveRecord::Base
  attr_accessible :email, :user_name
  
  acts_as_google_authenticated
end

class CustomUser < ActiveRecord::Base
  attr_accessible :email, :user_name

  acts_as_google_authenticated :google_secret_column => :mfa_secret
end

describe Google::Authenticator::Rails do
  before do
    ROTP::Base32.stub!(:random_base32).and_return("5qlcip7azyjuwm36")
  end
  
  it 'implements counter based passwords' do
    Google::Authenticator::Rails::generate_password("test", 1).should == 812658
    Google::Authenticator::Rails::generate_password("test", 2).should == 73348
  end
  
  it 'implements time based password' do
    time = Time.parse("2012-08-07 11:11:11 AM +0700")
    Time.stub!(:now).and_return(time)
    Google::Authenticator::Rails::time_based_password("test").should == 472374
  end
  
  it 'can validate a code' do
    time = Time.parse("2012-08-07 11:11:11 AM +0700")
    Time.stub!(:now).and_return(time)
    Google::Authenticator::Rails::valid?(472374, "test").should be_true
  end
  
  it 'can create a secret' do
    Google::Authenticator::Rails::generate_secret.should == "5qlcip7azyjuwm36"
  end
  
  context 'integration with ActiveRecord'  do
    
    before do
      time = Time.parse("2012-08-07 11:11:00 AM +0700")
      Time.stub!(:now).and_return(time)
      @user = User.create(email: "test@test.com", user_name: "test_user")
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
      @user.set_google_secret!
      @user.google_secret.should == "5qlcip7azyjuwm36"
    end
    
    context 'secret column' do
      before do
        Google::Authenticator::Rails.stub!(:generate_secret).and_return("test")
        @user = CustomUser.create(email: "test@test.com", user_name: "test_user")
        @user.set_google_secret!
      end

      it 'validates code' do
        @user.google_authenticate(472374).should be_true
      end

      it 'generates a url for a qr code' do
        @user.google_qr_uri.should == "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest%40test.com%3Fsecret%3Dtest&chs=200x200"
      end
    end

    context 'qr codes' do
      
      it 'generates a url for a qr code' do
        @user.set_google_secret!
        @user.google_qr_uri.should == "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest%40test.com%3Fsecret%3D5qlcip7azyjuwm36&chs=200x200"
      end
      
      it 'can generate off any column' do
        @user.class.acts_as_google_authenticated :column_name => :user_name
        @user.set_google_secret!
        @user.google_qr_uri.should == "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest_user%3Fsecret%3D5qlcip7azyjuwm36&chs=200x200"
      end
      
      it 'can generate with a custom proc' do
        @user.class.acts_as_google_authenticated :method => Proc.new { |user| "#{user.user_name}@futureadvisor-admin" }
        @user.set_google_secret!
        @user.google_qr_uri.should == "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest_user%40futureadvisor-admin%3Fsecret%3D5qlcip7azyjuwm36&chs=200x200"
      end
      
      it 'can generate with a method symbol' do
        @user.class.acts_as_google_authenticated :method => :email
        @user.set_google_secret!
        @user.google_qr_uri.should == "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest%40test.com%3Fsecret%3D5qlcip7azyjuwm36&chs=200x200"
      end
      
      it 'can generate with a method string' do
        @user.class.acts_as_google_authenticated :method => "email"
        @user.set_google_secret!
        @user.google_qr_uri.should == "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest%40test.com%3Fsecret%3D5qlcip7azyjuwm36&chs=200x200"
      end
      
    end
    
  end
  
end