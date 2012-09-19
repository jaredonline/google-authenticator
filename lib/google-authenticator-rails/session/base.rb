module GoogleAuthenticatorRails
  module Session
    class Base
      include Activation
      include Persistence
    end
  end
end