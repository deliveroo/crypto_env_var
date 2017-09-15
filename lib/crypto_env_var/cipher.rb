require "openssl"

module CryptoEnvVar
  class Cipher
    SEPARATOR = "--".freeze
    DIGEST_SEPARATOR = "----".freeze


    def initialize(key_string)
      @key = OpenSSL::PKey::RSA.new(key_string)
    end


    def encrypt(plaintext)
      ciphertext, key, iv = aes_encrypt(plaintext)

      ciphertext = encode(ciphertext)
      key        = encode(rsa_encrypt(key))
      iv         = encode(iv)
      payload    = [key, iv, ciphertext].join(SEPARATOR)
      digest     = encode(rsa_encrypt(sha2_digest(payload)))

      [payload, digest].join(DIGEST_SEPARATOR)
    end


    def decrypt(data)
      payload, digest = data.split(DIGEST_SEPARATOR)

      digest = rsa_decrypt(decode(digest))
      validate_digest!(payload, digest)

      key, iv, ciphertext = payload.split(SEPARATOR)

      ciphertext = decode(ciphertext)
      key        = rsa_decrypt(decode(key))
      iv         = decode(iv)

      aes_decrypt(ciphertext, key, iv)
    end


    private


    # Plain RSA private key encryption.
    # It can only encrypt data smaller than the key size.
    #
    def rsa_encrypt(plaintext)
      @key.private_encrypt(plaintext)
    end


    # Plain RDS public key decryption.
    # It can only decrypt data encrypted with the private
    # key from the keypair.
    #
    def rsa_decrypt(ciphertext)
      @key.public_decrypt(ciphertext)
    end


    # AES simmetric encryption.
    #
    def aes_encrypt(plaintext)
      cipher = OpenSSL::Cipher::AES256.new(:CBC)
      cipher.encrypt
      key = cipher.random_key
      iv = cipher.random_iv

      ciphertext = cipher.update(plaintext) + cipher.final

      [ciphertext, key, iv]
    end


    # AES simmetric decryption.
    #
    def aes_decrypt(ciphertext, key, iv)
      cipher = OpenSSL::Cipher::AES256.new(:CBC)
      cipher.decrypt
      cipher.key = key
      cipher.iv = iv
      
      cipher.update(ciphertext) + cipher.final
    end


    def sha2_digest(data)
      OpenSSL::Digest::SHA256.new.digest(data)
    end


    def validate_digest!(plaintext, digest)
      unless sha2_digest(plaintext) == digest
        raise DigestVerificationError
      end
    end


    def encode(data)
      Utils.encode(data)
    end


    def decode(data)
      Utils.decode(data)
    end


    class DigestVerificationError < StandardError
      def message
        "The payload has been tampered with."
      end
    end
  end
end
