require "binary_serializer"

class Person < ActiveRecord::Base
  include Vault::EncryptedModel

  vault_attribute :county_plaintext, encrypted_column: :county_encrypted
  vault_attribute_proxy :county, :county_plaintext

  vault_attribute :state_plaintext, encrypted_column: :state_encrypted
  vault_attribute_proxy :state, :state_plaintext, encrypted_attribute_only: true

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

  vault_attribute :email, convergent: true

  vault_attribute :integer_data,
    type: :integer,
    serialize: :integer

  vault_attribute :float_data,
    type: :float,
    serialize: :float

  vault_attribute :time_data,
    type: ActiveRecord::Type::Time.new,
    encode: -> (raw) { raw.to_s if raw },
    decode: -> (raw) { raw.to_time if raw }
end
