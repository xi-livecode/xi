# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'xi/version'

Gem::Specification.new do |spec|
  spec.name          = "xi-lang"
  spec.version       = Xi::VERSION
  spec.authors       = ["Damián Silvani"]
  spec.email         = ["munshkr@gmail.com"]

  spec.summary       = %q{Musical pattern language for livecoding}
  spec.description   = %q{A musical pattern language inspired in Tidal and SuperCollider
                          for building higher-level musical constructs easily.}
  spec.homepage      = "https://github.com/xi-livecode/xi"
  spec.license       = "GPL-3.0-or-later"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-minitest"
  spec.add_development_dependency "yard"

  spec.add_dependency 'pry'
  spec.add_dependency 'osc-ruby'
end
