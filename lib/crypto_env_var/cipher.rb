require "openssl"
require "msgpack"

module CryptoEnvVar
  class Cipher
    VERSION = "v1".freeze # To support multiple versions in the future


    # Can be initialized with a private or public
    # RSA key.
    # - private: encrypt and decrypt.
    # - public: decrypt only.
    #
    def initialize(key_string)
      @key = OpenSSL::PKey::RSA.new(key_string)
    end


    # Encrypt the plaintext with symmetric AES.
    #
    # Encrypt the AES key with the private RSA key.
    #
    # Join the encrypted text, the encrypted key and
    # the initialization vector in a payload string.
    #
    # Get a digest of the the payload, then encrypt
    # it with the private RSA key and append it to
    # the payload.
    #
    def encrypt(plaintext)
      ciphertext, key, iv = aes_encrypt(plaintext)

      key     = rsa_encrypt(key)
      payload = [VERSION, key, iv, ciphertext].to_msgpack
      digest  = rsa_encrypt(sha2_digest(payload))

      [payload, digest].to_msgpack
    end


    # Extract the digest, decrypt it with the RSA
    # public key, then validate the integrity of the
    # rest of the payload.
    #
    # Decrypt the AES key with the RSA public key.
    #
    # Decrypt the ciphertext with symmetric AES.
    #
    def decrypt(data)
      payload, digest = MessagePack.unpack(data)

      digest = rsa_decrypt(digest)
      validate_digest!(payload, digest)

      _version, key, iv, ciphertext = MessagePack.unpack(payload)

      key = rsa_decrypt(key)

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


    # AES symmetric encryption.
    #
    def aes_encrypt(plaintext)
      cipher = build_aes_ciper
      cipher.encrypt
      key = cipher.random_key
      iv = cipher.random_iv

      ciphertext = cipher.update(plaintext) + cipher.final

      [ciphertext, key, iv]
    end


    # AES symmetric decryption.
    #
    def aes_decrypt(ciphertext, key, iv)
      cipher = build_aes_ciper
      cipher.decrypt
      cipher.key = key
      cipher.iv = iv
      
      cipher.update(ciphertext) + cipher.final
    end


    def build_aes_ciper
      OpenSSL::Cipher::AES256.new(:CBC)
    end


    def sha2_digest(data)
      OpenSSL::Digest::SHA512.new.digest(data)
    end


    def validate_digest!(plaintext, digest)
      unless sha2_digest(plaintext) == digest
        raise DigestVerificationError
      end
    end


    class DigestVerificationError < StandardError
      def message
        "The payload has been tampered with."
      end
    end
  end
end
