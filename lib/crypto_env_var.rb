require "crypto_env_var/version"
require "crypto_env_var/cipher"
require "crypto_env_var/utils"


module CryptoEnvVar
  class << self
    def encrypt(data, private_key_string)
      json = CryptoEnvVar::Utils.serialize(data)

      cipher = CryptoEnvVar::Cipher.new(private_key_string)
      encrypted_data = cipher.encrypt(json)

      CryptoEnvVar::Utils.encode(encrypted_data)
    end


    def decrypt(string, public_key_string)
      encrypted_data = CryptoEnvVar::Utils.decode(string)

      cipher = CryptoEnvVar::Cipher.new(public_key_string)
      json = cipher.decrypt(encrypted_data)

      CryptoEnvVar::Utils.deserialize(json)
    end
  end
end
