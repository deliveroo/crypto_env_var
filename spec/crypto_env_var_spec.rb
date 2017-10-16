require 'spec_helper'

RSpec.describe CryptoEnvVar do
  let(:aes_key) { OpenSSL::Cipher::AES256.new(:CBC).random_key }
  let(:data) { {'BACON' => 'tasty'} }
  let(:encrypted_env) { described_class.encrypt(data, aes_key) }

  it { expect(encrypted_env).not_to include 'tasty' }

  describe '.bootstrap!' do
    let(:target) { {'BACON' => 'delicious'} }
    let(:strategy) do
      CryptoEnvVar::Strategy::External.new(
        aes_key: aes_key,
        encrypted_env: encrypted_env,
      )
    end
    let(:call) do
      described_class.bootstrap!(
        strategy: strategy,
        target: target,
        override: override,
      )
    end

    context 'with override' do
      let(:override) { true }

      it 'updates the target value' do
        expect { call }
          .to change { target['BACON'] }
          .from('delicious')
          .to('tasty')
      end
    end

    context 'without override' do
      let(:override) { false }

      it 'does not update the target value' do
        expect { call }
          .not_to change { target['BACON'] }
          .from('delicious')
      end
    end
  end
end
