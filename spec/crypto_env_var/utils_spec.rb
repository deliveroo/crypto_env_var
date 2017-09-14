require "spec_helper"
require "securerandom"

RSpec.describe CryptoEnvVar::Utils do
  describe "JSON serialization of Hashes" do
    let(:data) do
      {
        "ROMULUS" => SecureRandom.urlsafe_base64(100),
        "NUMA_POMPILIUS" => SecureRandom.urlsafe_base64(100),
        "TULLUS_HOSTILIUS" => SecureRandom.urlsafe_base64(100),
        "ANCUS_MARCIUS" => SecureRandom.urlsafe_base64(100),
        "LUCIUS_TARQUINIUS_PRISCUS" => SecureRandom.urlsafe_base64(100),
        "SERVIUS_TULLIUS" => SecureRandom.urlsafe_base64(100),
        "LUCIUS_TARQUINIUS_SUPERBUS" => SecureRandom.urlsafe_base64(100)
      }
    end


    it "serializes and deserializes Ruby Hashes" do
      json = described_class.serialize(data)

      expect(json).to be_a(String)

      out = described_class.deserialize(json)
      expect(out).to eql(data)
    end
  end


  describe "base64 encoding of raw data" do
    let(:data) { SecureRandom.random_bytes(1000) }

    specify "the raw data is indeed raw" do
      expect(data).to be_a String
      expect(data.force_encoding("UTF-8").valid_encoding?).to be false
      expect(data.ascii_only?).to be false
    end


    it "encodes and decodes bytes as a string" do
      base64 = described_class.encode(data)

      expect(base64).to be_a String
      expect(base64).to_not eql(data)

      out = described_class.decode(base64)
      expect(out).to eql(data)
    end


    specify "the encoded string is printable and portable" do
      base64 = described_class.encode(data)

      expect(base64.force_encoding("UTF-8").valid_encoding?).to be true
      expect(base64.ascii_only?).to be true
    end
  end
end



