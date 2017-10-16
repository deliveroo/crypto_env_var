# frozen_string_literal: true

require 'crypto_env_var/cipher'
require 'crypto_env_var/strategy'
require 'crypto_env_var/utils'
require 'crypto_env_var/version'

module CryptoEnvVar
  FROM_ENV = CryptoEnvVar::Strategy::FromEnv.new

  class << self
    # This method reeks of :reek:BooleanParameter and :reek:FeatureEnvy.
    def bootstrap!(strategy: FROM_ENV, target: ENV, override: true)
      decrypt(strategy.encrypted_env, strategy.aes_key).each do |key, value|
        next if !override && target.member?(key)
        target[key] = value
      end
    end

    def decrypt(data, aes_key)
      cipher = Cipher.new(aes_key)
      Utils.deserialize(cipher.decrypt(Utils.decode(data)))
    end

    def encrypt(data, aes_key)
      cipher = Cipher.new(aes_key)
      Utils.encode(cipher.encrypt(Utils.serialize(data)))
    end
  end
end
