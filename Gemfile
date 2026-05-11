# Copyright IBM Corp. 2015, 2026
# SPDX-License-Identifier: MPL-2.0

source "https://rubygems.org"

RAILS_VERSION = ENV.fetch("RAILS_VERSION", "7.2.0")

gem "rails", "~> #{RAILS_VERSION}"

# Rails versions before 7.1 have a dependency on concurrent-ruby but
# we need to pin to 1.3.4 because later versions removed a dependency on Logger
# that we need to start tests.
gem "concurrent-ruby", "1.3.4"

gemspec
