# coding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'homebrew/github/bottles/version'

Gem::Specification.new do |spec|
  spec.name          = "brew-github-bottles"
  spec.version       = Homebrew::Github::Bottles::VERSION
  spec.authors       = ["Jacob Meacham"]
  spec.email         = ["jacob.e.meacham@gmail.com"]
  spec.summary       = "Allows homebrew to use github releases as a bottle repository."
  spec.description   = "This gem lets homebrew use a github release as a bottle repository, including private repos."
  spec.homepage      = "https://github.com/jacob-meacham/brew-github-bottles"
  spec.license       = "MIT"
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "coveralls"

end
