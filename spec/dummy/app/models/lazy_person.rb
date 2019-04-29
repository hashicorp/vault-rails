require "binary_serializer"

class LazyPerson < ActiveRecord::Base
  include Vault::EncryptedModel

  self.table_name = "people"

  vault_lazy_decrypt!

  vault_attribute :ssn

  vault_attribute :credit_card,
    encrypted_column: :cc_encrypted,
    path: "credit-secrets",
    key: "people_credit_cards"

  vault_attribute :details,
    serialize: :json

  vault_attribute :business_card,
    serialize: BinarySerializer

  vault_attribute :favorite_color,
    encode: ->(raw) { "xxx#{raw}xxx" },
    decode: ->(raw) { raw && raw[3...-3] }

  vault_attribute :non_ascii

  vault_attribute :symbol_key,
    key: :encryption_key

  vault_attribute :proc_key,
    key: ->(record) { record.encryption_key }

  def encryption_key
    "person_#{id}"
  end
end
