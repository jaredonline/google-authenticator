require 'spec_helper'

@@secret = '5qlcip7azyjuwm36'

describe GoogleAuthenticatorRails do
  describe '#generate_password' do
    subject { GoogleAuthenticatorRails::generate_password("test", counter) }

    context 'counter = 1' do
      let(:counter) { 1 }
      it { should == "868864" }
    end

    context 'counter = 2' do
      let(:counter) { 2 }
      it { should == "304404" }
    end
  end

  context 'time-based passwords' do
    let(:secret)         { @@secret }
    let(:original_time)  { Time.parse("2012-08-07 11:11:00 AM +0700") }
    let!(:time)          { original_time }
    let(:code)           { "495502" }

    before do
      allow(Time).to receive(:now).and_return(time)
      allow(ROTP::Base32).to receive(:random_base32).and_return(secret)
    end

    specify { GoogleAuthenticatorRails::time_based_password(secret).should == code }
    specify { GoogleAuthenticatorRails::valid?(code, secret).should be true }

    specify { GoogleAuthenticatorRails::valid?(code * 2, secret).should be false }
    specify { GoogleAuthenticatorRails::valid?(code, secret * 2).should be false }

    it 'can create a secret' do
      GoogleAuthenticatorRails::generate_secret.should == secret
    end

    context 'integration with ActiveRecord' do
      let(:user) { UserFactory.create User }

      before do
        @user = user
        user.google_secret = secret
      end
  
      context "custom drift" do
        # 30 seconds drift
        let(:user) { UserFactory.create DriftUser }
        subject { user.google_authentic?(code) }
  
        context '6 seconds of drift' do
          let(:time)  { original_time + 36.seconds }
          it          { should be true }
        end
  
        context '30 seconds of drift' do
          let(:time)  { original_time + 61.seconds }
          it          { should be false }
        end
      end
  
      context 'code validation' do
        subject { user.google_authentic?(code) }
  
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
        user.set_google_secret
        user.google_secret.should == secret
      end
      
      shared_examples 'handles nil secrets' do
        it 'clears a secret' do
          @user.clear_google_secret!
          @user.google_secret_value.should(be_nil) && @user.reload.google_secret_value.should(be_nil)
        end
      end

      it_behaves_like 'handles nil secrets'

      context 'encrypted column' do
        before do
          @user = UserFactory.create EncryptedUser
          @user.set_google_secret
        end
        
        it 'encrypts_the_secret' do
          @user.google_secret.length.should == (GoogleAuthenticatorRails.encryption_supported? ? 138 : 16)
        end
        
        it 'decrypts_the_secret' do
          @user.google_secret_value.should == secret
        end        
        
        it 'validates code' do
          @user.google_authentic?(code).should be_truthy
        end

        it_behaves_like 'handles nil secrets'
      end
  
      context 'custom secret column' do
        before do
          @user = UserFactory.create CustomUser
          @user.set_google_secret
        end
  
        it 'validates code' do
          @user.google_authentic?(code).should be_truthy
        end
  
        it 'generates a url for a qr code' do
          @user.google_qr_uri.should == "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest%40example.com%3Fsecret%3D#{secret}&chs=200x200"
        end
      end
      
      context 'encrypted column with custom secret column' do
        before do
          @user = UserFactory.create EncryptedCustomUser
          @user.set_google_secret
        end
        
        it 'encrypts the secret' do
          @user.mfa_secret.length.should == (GoogleAuthenticatorRails.encryption_supported? ? 138 : 16)
        end
        
        it 'decrypts the secret' do
          @user.google_secret_value.should == secret
        end        
        
        it 'validates code' do
          @user.google_authentic?(code).should be_truthy
        end
      end
      
      if GoogleAuthenticatorRails.encryption_supported?
        context 'encryption Rake tasks' do
          before(:all) { Rails.application.load_tasks }
          
          def set_and_run_task(type)
            User.delete_all
            EncryptedCustomUser.delete_all 
            @user = UserFactory.create User
            @user.set_google_secret
            @encrypted_user = UserFactory.create EncryptedCustomUser
            @encrypted_user.set_google_secret
            @non_encrypted_user = UserFactory.create EncryptedCustomUser
            @non_encrypted_user.update_attribute(:mfa_secret, @@secret)
            Rake.application.invoke_task("google_authenticator:#{type}_secrets[User,EncryptedCustomUser]")
          end  
            
          def encryption_ok?(user, secret_should_be_encrypted)
            secret_value = user.reload.send(:google_secret_column_value)
            (secret_value.blank? || secret_value.length.should == (secret_should_be_encrypted ? 138 : 16)) &&
            (user.class.google_secrets_encrypted ^ secret_should_be_encrypted || user.google_secret_value == secret)
          end
  
          shared_examples 'task tests' do |type|
            it 'handles non-encrypted secrets' do
              encryption_ok?(@non_encrypted_user, type == 'encrypt')
            end
            
            it 'handles encrypted secrets' do
              encryption_ok?(@encrypted_user, type != 'decrypt')
            end
            
            it "doesn't #{type} non-encrypted models" do
              encryption_ok?(@user, false)
            end
          end
          
          context 'encrypt_secrets task' do
            before(:all) { set_and_run_task('encrypt') }
            it_behaves_like 'task tests', 'encrypt'
          end
          
          context 'decrypt_secrets task' do
            before(:all) { set_and_run_task('decrypt') }
            it_behaves_like 'task tests', 'decrypt'
          end
          
          context 'reencrypt_secrets task' do
            before(:all) do
              def reset_encryption(secret_key_base)
                Rails.application.secrets[:secret_key_base] = secret_key_base
                Rails.application.instance_eval { @caching_key_generator = nil }
                GoogleAuthenticatorRails.secret_encryptor = nil
              end
              
              current_secret_key_base = Rails.application.secrets[:secret_key_base]
              reset_encryption(Rails.application.secrets.old_secret_key_base)
              set_and_run_task('reencrypt')
              reset_encryption(current_secret_key_base)
            end
            
            it_behaves_like 'task tests', 'reencrypt'
          end
        end
      end
      
      context 'google label' do
        let(:user)    { UserFactory.create NilMethodUser }
        subject       { lambda { user.google_label } }
        it            { should raise_error(NoMethodError) }
      end
  
      context "drift value" do
        it { DriftUser.google_drift.should == 31 }
  
        context "default value" do
          it { User.google_drift.should == 6 }
        end
      end
  
      context 'qr codes' do
        let(:user)  { UserFactory.create User }
        before      { user.set_google_secret }
        subject     { user.google_qr_uri }
  
        it { should eq "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest%40example.com%3Fsecret%3D#{secret}&chs=200x200" }
  
        context 'custom column name' do
          let(:user) { UserFactory.create ColumnNameUser }
          it { should eq "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest_user%3Fsecret%3D#{secret}&chs=200x200" }
        end
  
        context 'custom proc' do
          let(:user) { UserFactory.create ProcLabelUser }
          it { should eq "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest_user%40futureadvisor-admin%3Fsecret%3D#{secret}&chs=200x200" }
        end
        
        context 'custom issuer' do
          let(:user) { UserFactory.create ProcIssuerUser }
          it { should eq "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2FFA%2520Admin%3Atest%40example.com%3Fsecret%3D#{secret}%26issuer%3DFA%2BAdmin&chs=200x200" }
        end
  
        context 'method defined by symbol' do
          let(:user) { UserFactory.create SymbolUser }
          it { should eq "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest%40example.com%3Fsecret%3D#{secret}&chs=200x200" }
        end
  
        context 'method defined by string' do
          let(:user) { UserFactory.create StringUser }
          it { should eq "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest%40example.com%3Fsecret%3D#{secret}&chs=200x200" }
        end
  
        context 'custom qr size' do
          let(:user) { UserFactory.create QrCodeUser }
          it { should eq "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest%40example.com%3Fsecret%3D#{secret}&chs=300x300" }
        end
  
        context 'qr size passed to method' do
          subject { user.google_qr_uri('400x400') }
          let(:user) { UserFactory.create StringUser }  
          it { should eq "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest%40example.com%3Fsecret%3D#{secret}&chs=400x400" }
        end
  
        context 'qr size passed to method and size set on model' do
          let(:user) { UserFactory.create QrCodeUser }
          subject { user.google_qr_uri('400x400') }
          it { should eq "https://chart.googleapis.com/chart?cht=qr&chl=otpauth%3A%2F%2Ftotp%2Ftest%40example.com%3Fsecret%3D#{secret}&chs=400x400" }
        end

        context 'generates base64 image' do
          let(:user) { UserFactory.create QrCodeUser }
          it { user.google_qr_to_base64.include?('data:image/png;base64').should be_truthy }
        end
      end
    end
  end
end
