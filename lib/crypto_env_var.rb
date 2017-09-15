require "crypto_env_var/version"
require "crypto_env_var/cipher"
require "crypto_env_var/utils"


module CryptoEnvVar
  class << self
    def encrypt(data, private_key_string)
      json = Utils.serialize(data)
      cipher = Cipher.new(private_key_string)
      encrypted_data = cipher.encrypt(json)
      Utils.encode(encrypted_data)
    end


    def decrypt(string, public_key_string)
      encrypted_data = Utils.decode(string)
      cipher = Cipher.new(public_key_string)
      json = cipher.decrypt(encrypted_data)
      Utils.deserialize(json)
    end
  end
end
