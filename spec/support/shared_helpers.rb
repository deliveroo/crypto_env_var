module SharedHelpers
  def private_key
    $private_key ||= begin
      path = File.expand_path("../keypairs/crypto_env_var.dev_test.id_rsa", __FILE__)
      File.read(path)
    end
  end

  def public_key
    $public_key ||= begin
      path = File.expand_path("../keypairs/crypto_env_var.dev_test.id_rsa.pub", __FILE__)
      File.read(path)
    end
  end
end
