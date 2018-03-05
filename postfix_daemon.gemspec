
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "postfix_daemon/version"

Gem::Specification.new do |spec|
  spec.name          = "postfix_daemon"
  spec.version       = PostfixDaemon::VERSION
  spec.licenses      = ['MIT']
  spec.authors       = ["TOMITA Masahiro"]
  spec.email         = ["tommy@tmtm.org"]

  spec.summary       = 'Postfix daemon'
  spec.description   = 'Postfix daemon'
  spec.homepage      = 'https://github.com/tmtm/postfix_daemon'

  spec.files         = %w(README.md sample/postfix_daemon-sample.rb lib/postfix_daemon.rb lib/postfix_daemon/version.rb)

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
