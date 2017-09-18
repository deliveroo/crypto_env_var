require "spec_helper"

RSpec.describe CryptoEnvVar do
  describe "bootstrapping the ENV Hash" do
    def clean_the_env
      ENV.delete(CryptoEnvVar::CRYPTO_ENV_VAR)
      ENV.delete(CryptoEnvVar::DECRYPT_KEY_VAR)
      SECRET_HASH.keys.each { |k| ENV.delete(k) }
    end

    before { clean_the_env }
    after(:all) { clean_the_env }

    # make this available in the class scope
    SECRET_HASH = {
      "ROMEO" => "Romeo and Juliet (1976)",
      "IAGO" => "Othello (1989)",
      "MAGNETO" => "X-Men (2000)",
      "GANDALF" => "The Fellowship of the Ring (2001)",
    }

    let(:secret_hash) { SECRET_HASH }
    let(:encrypted_env) do
      described_class.encrypt(secret_hash, private_key)
    end

    shared_examples_for "it populates the ENV with the encrypted variables" do |options|
      to_skip = Array((options || {})[:except])
      to_test = SECRET_HASH.reject { |k, _| to_skip.include?(k) }

      to_test.each do |k, v|
        it "sets the #{k} key" do
          expect { subject }.to change { ENV[k] }.from(nil).to(v)
        end
      end
    end

    shared_examples_for "it does NOT populate the ENV with the encrypted variables" do
      SECRET_HASH.each do |k, v|
        it "doesn't set the #{k} key" do
          expect { subject rescue nil }.to_not change { ENV[k] }
        end
      end
    end

    shared_examples_for "empty source ENV, bootstrapping failures" do
      describe "when the ENV does NOT contain the default source data" do
        context "any of them" do
          it "raises a KeyError error" do
            expect { subject }.to raise_error(KeyError)
          end

          it_behaves_like "it does NOT populate the ENV with the encrypted variables"
        end

        context "no CRYPTO_ENV source ENV var" do
          before do
            ENV[CryptoEnvVar::DECRYPT_KEY_VAR] = public_key
          end

          it "raises a KeyError error" do
            expect { subject }.to raise_error(KeyError)
          end

          it_behaves_like "it does NOT populate the ENV with the encrypted variables"
        end

        context "no DECRYPT_KEY source ENV var" do
          before do
            ENV[CryptoEnvVar::CRYPTO_ENV_VAR] = encrypted_env
          end

          it "raises a KeyError error" do
            expect { subject }.to raise_error(KeyError)
          end

          it_behaves_like "it does NOT populate the ENV with the encrypted variables"
        end
      end
    end

    shared_examples_for "it does NOT override already defined ENV variables" do
      describe "when there are no clashes with the pre-existing ENV" do
        it_behaves_like "it populates the ENV with the encrypted variables"
      end

      describe "when there some variables are already set in the ENV" do
        before do
          ENV["GANDALF"] = "already set"
          ENV["ROMEO"] = "already set"
        end

        it_behaves_like "it populates the ENV with the encrypted variables", except: %w(GANDALF ROMEO)

        describe "it doesn't change the alteady set variables" do
          it "doesn't change GANDALF" do
            expect { subject }.to_not change { ENV["GANDALF"] }.from("already set")
          end

          it "doesn't change ROMEO" do
            expect { subject }.to_not change { ENV["ROMEO"] }.from("already set")
          end
        end
      end
    end


    describe "the default behaviour, without arguments" do
      subject { described_class.bootstrap! }

      describe "when the ENV contains the default source data" do
        before do
          ENV[CryptoEnvVar::CRYPTO_ENV_VAR] = encrypted_env
          ENV[CryptoEnvVar::DECRYPT_KEY_VAR] = public_key
        end

        it_behaves_like "it populates the ENV with the encrypted variables"
      end

      include_examples "empty source ENV, bootstrapping failures"
    end


    describe "when overriding the ENV is disabled" do
      subject { described_class.bootstrap!(override_env: false) }

      describe "when the ENV contains the default source data" do
        before do
          ENV[CryptoEnvVar::CRYPTO_ENV_VAR] = encrypted_env
          ENV[CryptoEnvVar::DECRYPT_KEY_VAR] = public_key
        end

        it_behaves_like "it does NOT override already defined ENV variables"
      end

      include_examples "empty source ENV, bootstrapping failures"
    end


    describe "the source for the encrypted ENV and the decryption key can be customized" do
      describe "with plain strings" do
        subject do
          described_class.bootstrap!(
            read_from: encrypted_env.to_s,
            decrypt_with: public_key.to_s
          )
        end
        
        it_behaves_like "it populates the ENV with the encrypted variables"

        describe "when overriding the ENV is disabled" do
          subject do
            described_class.bootstrap!(
              read_from: encrypted_env.to_s,
              decrypt_with: public_key.to_s,
              override_env: false
            )
          end

          it_behaves_like "it does NOT override already defined ENV variables"
        end
      end


      describe "with callable strategies" do
        subject do
          described_class.bootstrap!(
            read_from: proc {
              File.read(File.expand_path("../fixtures/encrypted_env.txt", __FILE__)).chomp
            },
            decrypt_with: proc {
              File.read(File.expand_path("../support/keypairs/crypto_env_var.dev_test.id_rsa.pub", __FILE__)).chomp
            }
          )
        end

        it_behaves_like "it populates the ENV with the encrypted variables"

        describe "when overriding the ENV is disabled" do
          subject do
            described_class.bootstrap!(
              read_from: proc {
                File.read(File.expand_path("../fixtures/encrypted_env.txt", __FILE__)).chomp
              },
              decrypt_with: proc {
                File.read(File.expand_path("../support/keypairs/crypto_env_var.dev_test.id_rsa.pub", __FILE__)).chomp
              },
              override_env: false
            )
          end

          it_behaves_like "it does NOT override already defined ENV variables"
        end
      end
    end
  end


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
