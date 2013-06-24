# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'klepto/version'

Gem::Specification.new do |gem|
  gem.name          = "klepto"
  gem.version       = Klepto::VERSION
  gem.authors       = ["Cory O'Daniel"]
  gem.email         = ["github@coryodaniel.com"]
  gem.description   = "Tearing up web pages into ActiveRecord resources"
  gem.summary       = "Tearing up web pages into ActiveRecord resources"
  gem.homepage      = "http://github.com/coryodaniel/klepto"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  
  gem.add_dependency "poltergeist", '~> 1.3.0'
  gem.add_dependency "capybara", '~> 2.1.0'
  #gem.add_dependency "docile"
  #gem.add_dependency "thor"
  gem.add_dependency "nokogiri", '~> 1.5.6'
  gem.add_dependency "activesupport"
  gem.add_dependency 'multi_json', '~> 1.0'
end