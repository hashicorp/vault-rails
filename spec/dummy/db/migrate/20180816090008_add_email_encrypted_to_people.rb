class AddEmailEncryptedToPeople < ActiveRecord::Migration[5.0]
  def change
    add_column :people, :email_encrypted, :string
  end
end
