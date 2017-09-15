require "json"
require "base64"

module CryptoEnvVar
  module Utils
    class << self
      def serialize(data)
        JSON.dump(data)
      end

      def deserialize(string)
        JSON.load(string)
      end

      def encode(string)
        Base64.strict_encode64(string)
      end

      def decode(string)
        Base64.strict_decode64(string)
      end
    end
  end
end
