class AddTimeDataEncryptedToPeople < ActiveRecord::Migration[5.0]
  def change
    add_column :people, :time_data_encrypted, :string
  end
end
