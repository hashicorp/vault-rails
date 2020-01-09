
class LazySinglePerson < ActiveRecord::Base
  include Vault::EncryptedModel

  self.table_name = "people"

  vault_lazy_decrypt!
  vault_single_decrypt!

  vault_attribute :ssn

  vault_attribute :credit_card,
    encrypted_column: :cc_encrypted

  def encryption_context
    "user_#{id}"
  end
end
