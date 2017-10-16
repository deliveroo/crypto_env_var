require 'spec_helper'
require 'securerandom'

RSpec.describe CryptoEnvVar::Utils do
  describe 'JSON serialization of Hashes' do
    let(:data) do
      {
        'ROMULUS' => SecureRandom.urlsafe_base64(100),
        'NUMA_POMPILIUS' => SecureRandom.urlsafe_base64(100),
        'TULLUS_HOSTILIUS' => SecureRandom.urlsafe_base64(100),
        'ANCUS_MARCIUS' => SecureRandom.urlsafe_base64(100),
        'LUCIUS_TARQUINIUS_PRISCUS' => SecureRandom.urlsafe_base64(100),
        'SERVIUS_TULLIUS' => SecureRandom.urlsafe_base64(100),
        'LUCIUS_TARQUINIUS_SUPERBUS' => SecureRandom.urlsafe_base64(100),
      }
    end

    describe 'serializes and deserializes Ruby Hashes' do
      let(:json) { described_class.serialize(data) }
      let(:out) { described_class.deserialize(json) }

      it { expect(json).to be_a(String) }
      it { expect(out).to eql(data) }
    end
  end

  describe 'base64 encoding of raw data' do
    let(:data) { SecureRandom.random_bytes(1000) }

    describe 'the raw data is indeed raw' do
      it { expect(data).to be_a String }
      it { expect(data.force_encoding('UTF-8').valid_encoding?).to be false }
      it { expect(data.ascii_only?).to be false }
    end

    describe 'encodes and decodes bytes as a string' do
      let(:base64) { described_class.encode(data) }
      let(:out) { described_class.decode(base64) }

      it { expect(base64).to be_a String }
      it { expect(base64).not_to eql(data) }
      it { expect(out).to eql(data) }
    end

    describe 'the encoded string is printable and portable' do
      let(:base64) { described_class.encode(data) }

      it { expect(base64.force_encoding('UTF-8').valid_encoding?).to be true }
      it { expect(base64.ascii_only?).to be true }
    end
  end
end
