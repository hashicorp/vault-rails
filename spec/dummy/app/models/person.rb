require "binary_serializer"

class Person < ActiveRecord::Base
  include Vault::EncryptedModel

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

  vault_attribute :default,
    default: "abc123"

  vault_attribute :default_with_serializer,
    serialize: :json,
    default: {}

  vault_attribute :context_string,
    context: "production"

  vault_attribute :context_symbol,
    context: :encryption_context

  vault_attribute :context_proc,
    context: ->(record) { record.encryption_context }

  vault_attribute :transform_ssn,
    transform_secret: {
      transformation: "social_sec"
    }

  vault_attribute :bad_transform,
    transform_secret: {
      transformation: "foobar_transformation"
    }

  vault_attribute :bad_role_transform,
    transform_secret: {
      transformation: "social_sec",
      role: "foobar_role"
    }

  def encryption_context
    "user_#{id}"
  end
end
