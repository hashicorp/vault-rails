$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "vault/rails"

require "rspec"

def vault_version_string
  @vault_version_string ||= `vault --version`
end

TEST_VAULT_VERSION = Gem::Version.new(vault_version_string.match(/(\d+\.\d+\.\d+)/)[1])

RSpec.configure do |config|
  # Prohibit using the should syntax
  config.expect_with :rspec do |spec|
    spec.syntax = :expect
  end

  # Allow tests to isolate a specific test using +focus: true+. If nothing
  # is focused, then all tests are executed.
  config.filter_run_when_matching :focus
  config.filter_run_excluding vault: lambda { |v|
    !vault_meets_requirements?(v)
  }
  config.filter_run_excluding ent_vault: lambda { |v|
    !vault_is_enterprise? || !vault_meets_requirements?(v)
  }
  config.filter_run_excluding non_ent_vault: lambda { |v|
    vault_is_enterprise? || !vault_meets_requirements?(v)
  }

  # Allow tests to isolate a specific test using +focus: true+. If nothing
  # is focused, then all tests are executed.
  config.filter_run(focus: true)
  config.run_all_when_everything_filtered = true

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end

def vault_is_enterprise?
  !!vault_version_string.match(/\+(?:ent|prem)/)
end

def vault_meets_requirements?(v)
  Gem::Requirement.new(v).satisfied_by?(TEST_VAULT_VERSION)
end

require File.expand_path("../dummy/config/environment.rb", __FILE__)
