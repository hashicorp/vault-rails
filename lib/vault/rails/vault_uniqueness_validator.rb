require 'active_record'

class VaultUniquenessValidator < ActiveRecord::Validations::UniquenessValidator
  def validate_each(record, attribute, value)
    attribute_options = vault_options(record, attribute)

    unless attribute_options[:convergent]
      raise 'You cannot check uniqueness of an attribute that is not convergently encrypted'
    end

    encrypted_column = attribute_options[:encrypted_column]

    encrypted_value = record.class.encrypt_value(attribute, value)

    super(record, encrypted_column, encrypted_value)
  end

  private

  def vault_options(record, attribute)
    record.class.__vault_attributes[attribute]
  end
end
