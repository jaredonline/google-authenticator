require 'spec_helper'

describe Google::Authenticator do
  
  it 'implements counter based passwords' do
    Google::Authenticator::generate_password("test", 1).should == 779484
    Google::Authenticator::generate_password("test", 2).should == 568376
  end
  
  it 'implements time based password' do
    time = DateTime.parse("2012-08-07 11:11:11 AM +0700")
    Google::Authenticator::time_based_password("test", time).should == 84271
  end
  
end