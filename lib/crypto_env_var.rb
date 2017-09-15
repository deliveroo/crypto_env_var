require "crypto_env_var/version"
require "crypto_env_var/cipher"
require "crypto_env_var/utils"


module CryptoEnvVar
  CRYPTO_ENV_VAR  = "CRYPTO_ENV"
  DECRYPT_KEY_VAR = "CRYPTO_ENV_DECRYPT_KEY"
  CRYPTO_ENV      = lambda { ENV.fetch(CRYPTO_ENV_VAR) }
  DECRYPT_KEY     = lambda { ENV.fetch(DECRYPT_KEY_VAR) }


  class << self
    def bootstrap!(read_from: CRYPTO_ENV, decrypt_with: DECRYPT_KEY, override_env: true)
      data = read_value(read_from)
      key  = read_value(decrypt_with)
      hash = decrypt(data, key)

      hash.each_pair do |key, value|
        next if (!override_env && ENV.member?(key))
        ENV[key] = value
      end
    end


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


    private


    def read_value(source)
      source.respond_to?(:call) ? source.call() : source
    end
  end
end
