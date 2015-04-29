require "vault/rails"

require_relative "../../../support/vault_server"

Vault.configure do |vault|
  vault.application = "dummy"
  vault.address     = RSpec::VaultServer.address
  vault.token       = RSpec::VaultServer.token
end
