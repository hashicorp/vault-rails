class AddFloatDataEncryptedToPeople < ActiveRecord::Migration[5.0]
  def change
    add_column :people, :float_data_encrypted, :string
  end
end
