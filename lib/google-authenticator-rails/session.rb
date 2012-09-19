SESSION_GOOGLE_AUTHENTICATOR_RAILS_PATH = GOOGLE_AUTHENTICATOR_RAILS_PATH + "session/"

[
  "activation",
  "persistence",
  
  "base"
].each do |library|
   require SESSION_GOOGLE_AUTHENTICATOR_RAILS_PATH + library
 end