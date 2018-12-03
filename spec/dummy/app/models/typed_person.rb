require "binary_serializer"

class TypedPerson < ActiveRecord::Base
  include Vault::EncryptedModel

  self.table_name = "people"

  # types with default serializers
  vault_attribute :integer_data, type: :integer

  vault_attribute :float_data, type: :float

  vault_attribute :time_data, type: :time

  vault_attribute :date_data, encrypted_column: :state_encrypted, type: :date

  vault_attribute :date_time_data, encrypted_column: :county_encrypted, type: :datetime

  # types that do not have default serializers
  vault_attribute :decimal_data, encrypted_column: :ssn_encrypted, type: :decimal

  vault_attribute :string_data, encrypted_column: :cc_encrypted, type: :string

  vault_attribute :text_data, encrypted_column: :address_encrypted, type: :text

  # overriding the default serializer
  vault_attribute :custom_date_time_data, type: :datetime, serialize: :date

  vault_attribute :custom_float_data,
                  type: :datetime,
                  encode: ->(float_value) { float_value.round.to_s },
                  decode: ->(decrypted_value) { decrypted_value.to_f.round }
end
