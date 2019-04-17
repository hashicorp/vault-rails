require "active_record"
require_relative "latest/encrypted_model"
require_relative "legacy/encrypted_model"

module Vault
  EncryptedModel = if Vault::Rails.latest?
    Latest::EncryptedModel
  else
    Legacy::EncryptedModel
  end
end
