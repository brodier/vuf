# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vuf/version'

Gem::Specification.new do |spec|
  spec.name          = "vuf"
  spec.version       = Vuf::VERSION
  spec.authors       = ["Bernard Rodier"]
  spec.email         = ["bernard.rodier@gmail.com"]
  spec.description   = %q{My Very Usefull Patterns}
  spec.summary       = %q{This gem provide usefulle patterns like workingpool,
  batch executor, object instance recyclor, etc..}
  spec.homepage      = "https://github.com/brodier/vuf"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
