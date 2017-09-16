# CryptoEnvVar

[![Build Status](https://travis-ci.org/deliveroo/crypto_env_var.svg?branch=master)](https://travis-ci.org/deliveroo/crypto_env_var)

**CryptoEnvVar** provides:

* [Asymmetric encryption](#asymmetric-encryption) of JSON-serializable Ruby objects using a RSA keypair.
* [Secrets management for the Ruby ENV](#secrets-management-for-the-ruby-env).

## Asymmetric Encryption

The gem provides two functions that can be used on their own, even without the ENV management functionality.

Any Ruby object that can be serialized and deserialized with `JSON.dump` nd `JSON.load` is a valid input. This means that you can use a Hash, but that symbols won't be preserved. The output is a base64-encoded string, safe to be stored and transferred as text.

```ruby
rsa_private_key_string = File.read("path/to/rsa_key.pem")
rsa_public_key_string  = File.read("path/to/rsa_key.pub.pem")

data = { "foo" => 42, "bar" => [1, 3, 3, 7], "baz" => true }

ciphertext = CryptoEnvVar.encrypt(data, rsa_private_key_string)
plaintext  = CryptoEnvVar.decrypt(ciphertext, rsa_public_key_string)

data == plaintext # true
```

While the public key can only be used to decrypt, the private key can be used to both encrypt and decrypt:

```ruby
a = CryptoEnvVar.decrypt(encrypted, rsa_private_key_string)
b = CryptoEnvVar.decrypt(encrypted, rsa_public_key_string)

a == b && a == data # true
```

## Secrets management for the Ruby ENV

A common practice when deploying applications is to customize their runtime behaviour by providing configuration in the system ENV.

Often this means that something, at some point, needs to get the raw configuration values and set them on the machine (or container, or Heroku dyno) that will run the application. Since the configuration usually contains sensitive values, for example database passwords and other auth credentials, this is less than ideal.

A solution is to encrypt the configuration data, set it in the ENV encrypted, and then allow the application to decrypt it when it boots. This library aims to make this pattern easier to adopt.

First off, the app configuration needs to be encrypted. This should ideally be done by an automated tool. For example:

```ruby
app_config = {
  "DB_URL" => "postgres://user:password123@thedb.hostname.com:1234/db_name",
  "CACHE_URL" => "redis://user:password456@another.url.com:5678",
  "PAYMENTS_GATEWAY_API_TOKEN" => "SECRET_TOKEN_ZOMG",
}

private_key = File.read("path/to/rsa_key.pem")

File.write("encrypted_env.txt",  CryptoEnvVar.encrypt(app_config, private_key))
```

Done that, the encrypted configuration and the public key need to be passed to the starting application. By default, `CryptoEnvVar` will try to read them from two ENV variables:

```
export CRYPTO_ENV='the base64 encrypted configuration generated above'
export CRYPTO_ENV_DECRYPT_KEY='the public key'

ruby my_app.rb
```

If you choose the default names, then all you need to do is call `CryptoEnvVar.bootstrap!` early in the application initialization process (for example in `config.ru` for a Rack app), and it will load and decrypt the encrypted env, then copy its data into the `ENV` of the current process.

```ruby
ENV["DB_URL"]
# => nil

CryptoEnvVar.bootstrap!

ENV["DB_URL"]
# => "postgres://user:password123@thedb.hostname.com:1234/db_name"
```


The sources of both the encrypted configuration and the public key can be configured with the `:read_from` and `:decrypt_with` options, respectively. Valid values are strings or callable objects (you can use a proc or lambda or you can implement your own loaders). For example:

```ruby
CryptoEnvVar.bootstrap!(
  read_from: -> { File.read(ENV["secrets_file_path"]).chomp },
  decrypt_with: SecurePublicKeyFetcher.new
)

class SecurePublicKeyFetcher
  def call
    # ...
  end
end
```


By default `CryptoEnvVar.bootstrap!` will copy all the decrypted configuration variables into the ENV, overriding any preset value. If you want to disable this, for example because you want any explicitly set ENV variable to have the precence, you can do so with this option:

```ruby
CryptoEnvVar.bootstrap!(override_env: false)
```


## A note on the RSA keypairs

Only keypairs without passphrase are supported at this stage.

You can create an RSA keypair in a shell with:

```
openssl genrsa -out private_key.pem 2048
openssl rsa -pubout -in private_key.pem -out public_key.pem
```

Please note that the public key is **NOT** the same thing as the SSH public key file [normally generated with `ssh-keygen`](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/). You can still use a private RSA key generated with `ssh-keygen`, but then you have to extract the public key with the `openssl` command shown above.

Alternatively, you can use the [OpenSSL classes](http://ruby-doc.org/stdlib-2.4.1/libdoc/openssl/rdoc/OpenSSL/PKey/RSA.html) from the Ruby standard library:

```ruby
require "openssl"

new_keypair     = OpenSSL::PKey::RSA.generate(2048)
new_private_key = new_keypair.to_s
new_public_key  = new_keypair.public_key.to_s

imported_keypair     = OpenSSL::PKey::RSA.new(File.read("private_rsa_key.pem"))
imported_private_key = imported_keypair.to_s
imported_public_key  = imported_keypair.public_key.to_s

imported_private_key == File.read("private_rsa_key.pem") # true
```


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'crypto_env_var'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install crypto_env_var


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/crypto_env_var.
