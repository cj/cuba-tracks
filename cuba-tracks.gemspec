# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cuba/tracks/version'

Gem::Specification.new do |spec|
  spec.name          = "cuba-tracks"
  spec.version       = Cuba::Tracks::VERSION
  spec.authors       = ["cj"]
  spec.email         = ["cjlazell@gmail.com"]
  spec.description   = %q{}
  spec.summary       = %q{}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "cuba", "~> 3.1.1"
  spec.add_dependency "cuba-sugar"
  spec.add_dependency "cutest"
  spec.add_dependency "pry"
  spec.add_dependency "pry-doc"
  spec.add_dependency "pry-rescue"
  spec.add_dependency "rack-protection", "~> 1.5.2"
end
