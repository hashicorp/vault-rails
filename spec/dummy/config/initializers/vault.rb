require "vault/rails"

require_relative "../../../support/vault_server"

Vault::Rails.configure do |vault|
  vault.application = "dummy"

  vault.address     = ENV['FC_VAULT_RAILS_DUMMY_VAULT_SERVER'] || RSpec::VaultServer.address
  vault.token       = ENV['FC_VAULT_RAILS_DUMMY_VAULT_TOKEN'] || RSpec::VaultServer.token
  vault.enabled     = true
end
