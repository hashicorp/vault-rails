$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "vault/rails/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "fc-vault-rails"
  s.version     = Vault::Rails::VERSION
  s.authors     = ["Funding Circle Engineering", "Seth Vargo"]
  s.email       = ["engineering+fc-vault-rails@fundingcircle.com", "sethvargo@gmail.com"]
  s.homepage    = "https://github.com/fundingcircle/fc-vault-rails"
  s.summary     = "Official Vault plugin for Rails"
  s.description = s.summary
  s.license     = "MPL-2.0"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "activerecord", ">= 4.2"
  s.add_dependency "vault", "~> 0.7"

  s.add_development_dependency "appraisal", "~> 2.1"
  s.add_development_dependency "bundler"
  s.add_development_dependency "rails", ">= 4.2"
  s.add_development_dependency "byebug"
  s.add_development_dependency "pry"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec",   "~> 3.2"
  s.add_development_dependency "sqlite3", '~> 1.3'
  s.add_development_dependency "oj"
end
