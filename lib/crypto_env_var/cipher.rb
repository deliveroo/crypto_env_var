require "openssl"

module CryptoEnvVar
  class Cipher
    def initialize(key_string)
      @key = OpenSSL::PKey::RSA.new(key_string)
    end

    def encrypt(plaintext)
      @key.private_encrypt(plaintext)
    end

    def decrypt(ciphertext)
      @key.public_decrypt(ciphertext)
    end
  end
end
