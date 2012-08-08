require "google-authenticator/version"
require 'active_support'
require 'openssl'

module Google
  module Authenticator
    DIGITS = 6
    
    def self.generate_password(secret, iteration, digits = DIGITS)
      sha1_hash = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new("SHA1"), secret, string_to_hex_value(iteration))
      
      offset = sha1_hash[-1].chr.hex
      
      
      dbc1 = sha1_hash[(offset * 2) .. (offset * 2) + 8]
      dbc2 = dbc1.hex & "7fffffff".hex
      hotp = dbc2 % (10**digits.to_i)
      sprintf("%0#{digits}d", hotp).to_i
    end
    
    def self.time_based_password(secret, time)
      time = (time.respond_to?(:utc) ? time.utc.to_i : time.to_i) / 30      
      generate_password(secret, time)
    end
    
    def self.string_to_hex_value(count, padding = nil, pad_char = "0")
      return_string = ""
      # Change count to an integer then base 16 convert to a string
      # i.e. 10.to_s(16)  = a
      hex_count = count.to_i.to_s(16) #string

      # Pad the resulting string with the pad_charater ("0" by default)
      # i.e. Takes "a" and makes it "000000a"
      # We multiply the padding by two since we evaluate the hex as two characters
      # i.e. "a" in hex is "0a"
      ((padding.to_i * 2) - hex_count.size).times { hex_count.insert(0, pad_char) } if padding
      hex_count = "0" + hex_count if hex_count.size % 2 == 1
      temp_char = "0"
      
      hex_count.scan(/../).each do |hexs|
        temp_char[0] = hexs.hex.to_s
        return_string << temp_char
      end
      
      return_string
    end
  end
end
