require "openssl"

module CryptoEnvVar
  class Cipher
    SEPARATOR = "--".freeze

    def initialize(key_string)
      @key = OpenSSL::PKey::RSA.new(key_string)
    end


    def encrypt(plaintext)
      digest = sha2_digest(plaintext)
      ciphertext, key, iv = aes_encrypt(plaintext)

      ciphertext = encode(ciphertext)
      key        = encode(rsa_encrypt(key))
      iv         = encode(iv)
      digest     = encode(digest)

      [key, iv, ciphertext, digest].join(SEPARATOR)
    end


    def decrypt(ciphertext)
      key, iv, ciphertext, digest = ciphertext.split(SEPARATOR)

      ciphertext = decode(ciphertext)
      key        = rsa_decrypt(decode(key))
      iv         = decode(iv)
      digest     = decode(digest)
      plaintext  = aes_decrypt(ciphertext, key, iv)

      validate_digest!(plaintext, digest)

      plaintext
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
        "Decryption successful, but the message has been tampered with"
      end
    end
  end
end
