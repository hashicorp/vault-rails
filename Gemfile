# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

source "https://rubygems.org"

RAILS_VERSION = ENV.fetch("RAILS_VERSION", "6.0.0")

gem "rails", "~> #{RAILS_VERSION}"

# Rails versions before 7.1 have a dependency on concurrent-ruby but 
# we need to pin to 1.3.4 because later versions removed a dependency on Logger
# that we need to start tests.
gem "concurrent-ruby", "1.3.4"

if RAILS_VERSION.start_with?("6")
  gem "sqlite3", "~> 1.4"
end

gemspec
