module CryptoEnvVar
  class Strategy
    def aes_key
      raise NotImplementedError
    end

    def encrypted_env
      raise NotImplementedError
    end

    class External < Strategy
      attr_reader :aes_key, :encrypted_env

      def initialize(aes_key:, encrypted_env:)
        @aes_key = aes_key
        @encrypted_env = encrypted_env
      end
    end

    class FromEnv < Strategy
      CRYPTO_ENV_VAR  = 'CRYPTO_ENV'.freeze
      DECRYPT_KEY_VAR = 'CRYPTO_ENV_DECRYPT_KEY'.freeze

      def initialize(env = ENV)
        @env = env
      end

      def aes_key
        CryptoEnvVar::Utils.decode(env.fetch(DECRYPT_KEY_VAR))
      end

      def encrypted_env
        env.fetch(CRYPTO_ENV_VAR)
      end

      private

      attr_reader :env
    end
  end
end
