require "spec_helper"

RSpec.describe CryptoEnvVar::Cipher do
  let(:plaintext) do
    <<-EOS
    How much wood could a woodchuck chuck 
    If a woodchuck could chuck wood? 
    As much wood as a woodchuck could chuck, 
    If a woodchuck could chuck wood.
    EOS
  end

  describe "a Cipher initialized with a private key" do
    subject { described_class.new(private_key) }

    it "can encrypt and decrypt a text" do
      ciphertext = subject.encrypt(plaintext)
      expect(ciphertext).to_not eq plaintext

      out = subject.decrypt(ciphertext)
      expect(out).to eq plaintext
    end

    describe "with a plaintext larger than the key size" do
      let(:plaintext) { super() * 20 }

      it "can encrypt and decrypt a text" do
        ciphertext = subject.encrypt(plaintext)
        expect(ciphertext).to_not eq plaintext

        out = subject.decrypt(ciphertext)
        expect(out).to eq plaintext
      end
    end
  end


  describe "a Cipher initialized with a public key" do
    subject { described_class.new(public_key) }

    let(:ciphertext) do
      described_class.new(private_key).encrypt(plaintext)
    end

    it "can decrypt a ciphertext encrypted with the matching private key" do
      out = subject.decrypt(ciphertext)
      expect(out).to eq plaintext
    end

    it "can't encrypt" do
      expect {
        subject.encrypt(plaintext)
      }.to raise_error OpenSSL::PKey::RSAError, /private key needed/
    end

    it "can't decrypt a ciphertext generated with a different private key" do
      other_private_key = OpenSSL::PKey::RSA.generate(2048)
      other_cyphertext = other_private_key.private_encrypt(plaintext)

      expect(
        other_private_key.public_decrypt(other_cyphertext)
      ).to eql plaintext

      expect {
        subject.decrypt(other_cyphertext)
      }.to raise_error OpenSSL::PKey::RSAError, /padding check failed/
    end
  end
end
