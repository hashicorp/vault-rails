require 'active_record'

class VaultUniquenessValidator < ActiveRecord::Validations::UniquenessValidator
  def validate_each(record, attribute, value)
    attribute_options = vault_options(record, attribute)

    unless attribute_options[:convergent]
      raise 'You cannot check uniqueness of an attribute that is not convergently encrypted'
    end

    encrypted_column = attribute_options[:encrypted_column]

    encrypted_value = value.present? ? encrypt_value(value, attribute_options) : value

    super(record, encrypted_column, encrypted_value)
  end

  private

  def vault_options(record, attribute)
    record.class.__vault_attributes[attribute]
  end

  def encrypt_value(value, attribute_options)
    key = attribute_options[:key]
    serializer = attribute_options[:serializer]

    plaintext = serializer ? serializer.encode(value) : value

    Vault::Rails.encrypt('transit', key, plaintext, Vault.client, true)
  end
end
