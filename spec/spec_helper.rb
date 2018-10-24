$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "vault/rails"

require "rspec"

RSpec.configure do |config|
  # Prohibit using the should syntax
  config.expect_with :rspec do |spec|
    spec.syntax = :expect
  end

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

require File.expand_path("../dummy/config/environment.rb", __FILE__)

# Mount the engines we need for testing
Vault::Rails.sys.mount("transit", :transit)
Vault::Rails.sys.mount("non-ascii", :transit)
Vault::Rails.sys.mount("credit-secrets", :transit)
