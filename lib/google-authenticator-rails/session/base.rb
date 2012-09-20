module GoogleAuthenticatorRails
  module Session
    # This is where the heart of the session control logic works.  
    # GoogleAuthenticatorRails works in the same way as Authlogic.  It assumes that you've created a class based on
    # GoogleAuthenticatorRails::Session::Base with the name of the model you want to authenticate + "MfaSession". So if you had
    #     
    #     class User < ActiveRecord::Base
    #     end
    # 
    # Your Session management class would look like
    # 
    #     class UserMfaSession < GoogleAuthenticatorRails::Session::Base
    #     end
    # 
    # The Session class gets the name of the record to lookup from the name of the class.
    # 
    # To create a new session based off our User class, you just call
    # 
    #     UserMfaSession.create(@user) # => <# UserMfaSession @record="<# User >">
    # 
    # Then, in your controller, you can lookup that session by calling
    # 
    #     UserMfaSession.find
    # 
    # You don't have to pass any arguments because only one session can be active at a time.
    # 
    class Base
      include Activation
      include Persistence
    end
  end
end