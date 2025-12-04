$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "vault/rails/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "vault-rails"
  s.version     = Vault::Rails::VERSION
  s.authors     = ["Seth Vargo"]
  s.email       = ["team-vault-devex@hashicorp.com"]
  s.homepage    = "https://github.com/hashicorp/vault-rails"
  s.summary     = "Official Vault plugin for Rails"
  s.description = s.summary
  s.license     = "MPL-2.0"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.required_ruby_version = ">= 3.1"

  s.add_dependency "activesupport", ">= 5.0"
  s.add_dependency "vault", "~> 0.19"
  # mutex_m was removed from Ruby's default gems in 3.4.0
  # Rails 6.0 depends on it but doesn't declare it explicitly
  s.add_dependency "mutex_m"
  # bigdecimal was removed from Ruby's default gems in 3.4.0
  # Rails 6.0 depends on it but doesn't declare it explicitly
  s.add_dependency "bigdecimal"

  s.add_development_dependency "bundler"
  s.add_development_dependency "pry"
  s.add_development_dependency "pry-byebug"
  s.add_development_dependency "rake",    "~> 12.3.3"
  s.add_development_dependency "rspec",   "~> 3.2"
  s.add_development_dependency "sqlite3", "~> 1.3.6"
  # ostruct will be removed from Ruby's default gems in 3.5.0
  # rake 12.3.3 depends on it but doesn't declare it explicitly
  s.add_development_dependency "ostruct"
end
