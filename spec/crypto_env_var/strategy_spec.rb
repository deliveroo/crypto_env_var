require 'spec_helper'

# rubocop:disable RSpec/NestedGroups
RSpec.describe CryptoEnvVar::Strategy do
  let(:strategy) { described_class.new }

  describe '#aes_key' do
    it { expect { strategy.aes_key }.to raise_error NotImplementedError }
  end

  describe '#encrypted_env' do
    it { expect { strategy.encrypted_env }.to raise_error NotImplementedError }
  end

  describe CryptoEnvVar::Strategy::External do
    let(:aes_key) { 'aes_key' }
    let(:encrypted_env) { 'encrypted_env' }
    let(:strategy) do
      described_class.new(aes_key: aes_key, encrypted_env: encrypted_env)
    end

    describe '#aes_key' do
      it { expect(strategy.aes_key).to eq aes_key }
    end

    describe '#encrypted_env' do
      it { expect(strategy.encrypted_env).to eq encrypted_env }
    end
  end

  describe CryptoEnvVar::Strategy::FromEnv do
    let(:strategy) { described_class.new(env) }

    describe '#aes_key' do
      let(:result) { strategy.aes_key }

      context 'valid key present' do
        let(:key) { OpenSSL::Cipher::AES256.new(:CBC).random_key }
        let(:valid) { CryptoEnvVar::Utils.encode(key) }
        let(:env) { {'CRYPTO_ENV_DECRYPT_KEY' => valid} }

        it { expect(result).to eq key }
      end

      context 'invalid key present' do
        let(:invalid) { 'bacon' }
        let(:env) { {'CRYPTO_ENV_DECRYPT_KEY' => invalid} }
        let(:error) { 'invalid base64' }

        it { expect { result }.to raise_error ArgumentError, error }
      end

      context 'key not present' do
        let(:env) { {} }

        it { expect { result }.to raise_error KeyError }
      end
    end

    describe '#encrypted_env' do
      let(:result) { strategy.encrypted_env }

      context 'environment present' do
        let(:crypto_env) { 'crypto_env' }
        let(:env) { {'CRYPTO_ENV' => crypto_env} }

        it { expect(result).to eq crypto_env }
      end

      context 'environment not present' do
        let(:env) { {} }

        it { expect { result }.to raise_error KeyError }
      end
    end
  end
end
