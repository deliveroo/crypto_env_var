require "spec_helper"

RSpec.describe CryptoEnvVar do
  describe "encryption and serialization" do
    let(:data) do
      {
        "FOO" => "BAR",
        "BAZ" => "QWE"
      }
    end

    it "can encrypt ruby hashes into a base64 string" do
      out = CryptoEnvVar.encrypt(data, private_key)

      expect(out).to be_a String
      expect(out.ascii_only?).to be true
    end

    it "can decrypt an encrypted base64 input, with a private_key" do
      input = CryptoEnvVar.encrypt(data, private_key)

      out = CryptoEnvVar.decrypt(input, private_key)
      expect(out).to eql(data)
    end

    it "can decrypt an encrypted base64 input, with a public_key" do
      input = CryptoEnvVar.encrypt(data, private_key)

      out = CryptoEnvVar.decrypt(input, public_key)
      expect(out).to eql(data)
    end
  end
end
