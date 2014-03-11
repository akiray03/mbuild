# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mruby/build/version'

Gem::Specification.new do |spec|
  spec.name          = "mruby-build"
  spec.version       = Mruby::Build::VERSION
  spec.authors       = ["Akira Yumiyama"]
  spec.email         = ["yumiyama.akira@gmail.com"]
  spec.summary       = %q{mruby and mrbgem build tool}
  spec.description   = ""
  spec.homepage      = "https://github.com/akiray03/mruby-build"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "term-ansicolor", "~> 1.0"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake", "~> 0"
end
