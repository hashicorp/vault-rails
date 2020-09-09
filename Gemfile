source "https://rubygems.org"

RAILS_VERSION = ENV.fetch("RAILS_VERSION", "6.0.0")

gem "rails", "~> #{RAILS_VERSION}"
if RAILS_VERSION.start_with?("6")
  gem "sqlite3", "~> 1.4"
end

gemspec
