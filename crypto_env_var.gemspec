lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'crypto_env_var/version'

Gem::Specification.new do |spec|
  spec.name          = 'crypto_env_var'
  spec.version       = CryptoEnvVar::VERSION
  spec.authors       = ['Tommaso Pavese']
  spec.email         = ['tommaso.pavese@deliveroo.co.uk']

  spec.summary       = 'Utilities to protect the application env'
  spec.description   = <<-DESCRIPTION
  Utilities to protect the application env.
  Use an AES key to encrypt an env Hash to a blob and populate the process ENV from the encryped blob.
  DESCRIPTION
  spec.homepage      = 'https://github.com/deliveroo/crypto_env_var'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.18'

  spec.add_development_dependency 'pry', '~> 0.10.4'
end
