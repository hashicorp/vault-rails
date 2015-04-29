class Person < ActiveRecord::Base
  include Vault::EncryptedModel
  vault_attribute :ssn
  vault_attribute :credit_card,
    encrypted_column: :cc_encrypted,
    path: "credit-secrets",
    key: "people_credit_cards"
end
