# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

require "vault/rails"

require_relative "../../../support/vault_server"

Vault::Rails.configure do |vault|
  vault.application = "dummy"
  vault.address     = RSpec::VaultServer.address
  vault.token       = RSpec::VaultServer.token
  vault.enabled     = true
end
