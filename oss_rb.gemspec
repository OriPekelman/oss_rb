# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'oss_rb/version'

Gem::Specification.new do |spec|
  spec.name          = "oss_rb"
  spec.version       = Oss::VERSION
  spec.authors       = ["Ori Pekelman"]
  spec.email         = ["ori@pekelman.com"]
  spec.description   = %q{Open Search Server Ruby Client}
  spec.summary       = %q{Open Search Server Ruby Client}
  spec.homepage      = "http://open-search-server.com/"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_dependency 'nokogiri'
  spec.add_dependency 'rest-client'
end
