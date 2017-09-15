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

  shared_examples_for "message integrity verification" do
    describe "when the encrypted payload has been tampered with" do
      let(:tampered_payload) do
        data = described_class.new(private_key).encrypt(plaintext)
        data[1], data[2] = data[2], data[1]
        data
      end

      it "fails early with a digest verification error" do
        expect {
          subject.decrypt(tampered_payload)
        }.to raise_error CryptoEnvVar::Cipher::DigestVerificationError
      end
    end
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

    include_examples "message integrity verification"    
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

    include_examples "message integrity verification"

    it "can't decrypt a ciphertext generated with a different private key" do
      other_cipher = described_class.new(OpenSSL::PKey::RSA.generate(2048))
      other_cyphertext = other_cipher.encrypt(plaintext)

      expect(
        other_cipher.decrypt(other_cyphertext)
      ).to eql plaintext

      expect {
        subject.decrypt(other_cyphertext)
      }.to raise_error OpenSSL::PKey::RSAError, /padding check failed/
    end
  end
end
