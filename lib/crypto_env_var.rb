require "crypto_env_var/version"
require "crypto_env_var/cipher"
require "crypto_env_var/utils"


module CryptoEnvVar
  class << self
    def encrypt(data, private_key_string)
      json = Utils.serialize(data)
      cipher = Cipher.new(private_key_string)
      cipher.encrypt(json)
    end


    def decrypt(string, public_key_string)
      cipher = Cipher.new(public_key_string)
      json = cipher.decrypt(string)
      Utils.deserialize(json)
    end
  end
end
