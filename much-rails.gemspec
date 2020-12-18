# -*- encoding: utf-8 -*-
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "much-rails/version"

Gem::Specification.new do |gem|
  gem.name        = "much-rails"
  gem.version     = MuchRails::VERSION
  gem.authors     = ["Kelly Redding", "Collin Redding"]
  gem.email       = ["kelly@kellyredding.com", "collin.redding@me.com"]
  gem.summary     = "Rails utilities."
  gem.description = "Rails utilities."
  gem.homepage    = "https://github.com/redding/much-rails"
  gem.license     = "MIT"

  gem.files         = `git ls-files | grep "^[^.]"`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = "~> 2.5"

  gem.add_development_dependency("assert", ["~> 2.18.4"])

  gem.add_dependency("activesupport", ["> 5.0", "< 7.0"])
  gem.add_dependency("much-plugin", ["~> 0.2.2"])
  gem.add_dependency("much-result", ["~> 0.1.2"])
end
