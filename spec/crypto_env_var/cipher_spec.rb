require 'spec_helper'

RSpec.describe CryptoEnvVar::Cipher do
  let(:aes_key) { OpenSSL::Cipher::AES256.new(:CBC).random_key }
  let(:cipher)  { described_class.new(aes_key) }
  let(:plaintext) do
    <<-PLAINTEXT
    How much wood could a woodchuck chuck
    If a woodchuck could chuck wood?
    As much wood as a woodchuck could chuck,
    If a woodchuck could chuck wood.
    PLAINTEXT
  end

  describe 'round trip' do
    let(:encrypted) { cipher.encrypt(plaintext) }
    let(:decrypted) { decipher.decrypt(encrypted) }

    context 'with the same AES key' do
      let(:decipher) { described_class.new(aes_key) }

      it { expect(decrypted).to eq plaintext }
    end

    context 'with a different AES key' do
      let(:other_key) { OpenSSL::Cipher::AES256.new(:CBC).random_key }
      let(:decipher) { described_class.new(other_key) }

      it { expect { decrypted }.to raise_error OpenSSL::Cipher::CipherError }
    end
  end
end
