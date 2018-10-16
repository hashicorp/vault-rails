class AddIntegerDataEncryptedToPeople < ActiveRecord::Migration[5.0]
  def change
    add_column :people, :integer_data_encrypted, :string
  end
end
