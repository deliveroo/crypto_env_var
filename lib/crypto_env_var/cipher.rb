require 'openssl'

module CryptoEnvVar
  class Cipher
    IV_LENGTH = 16

    # Initialize with AES key.
    #
    # @param [String] aes_key
    def initialize(aes_key)
      @aes_key = aes_key
    end

    # Encrypt the plaintext with symmetric AES.
    # This method reeks of :reek:FeatureEnvy (of `cipher`).
    #
    # @param [String] plaintext
    # @return [String] IV concatenated with ciphertext
    def encrypt(plaintext)
      cipher = build_aes_cipher(&:encrypt)
      iv = cipher.random_iv
      ciphertext = cipher.update(plaintext) + cipher.final
      iv + ciphertext
    end

    # Split the payload into IV and ciphertext, and decrypt into plaintext.
    # This method reeks of :reek:FeatureEnvy (of `cipher`).
    #
    # @param [String] payload
    # @return [String] plaintext
    def decrypt(payload)
      iv = payload[0...IV_LENGTH]
      ciphertext = payload[IV_LENGTH..-1]
      cipher = build_aes_cipher(&:decrypt)
      cipher.iv = iv
      cipher.update(ciphertext) + cipher.final
    end

    private

    attr_reader :aes_key

    def build_aes_cipher
      OpenSSL::Cipher::AES256.new(:CBC).tap do |cipher|
        yield cipher
        cipher.key = aes_key
      end
    end
  end
end
