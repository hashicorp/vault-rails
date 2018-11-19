class AddPassportNumberToPeople < ActiveRecord::Migration[5.0]
  def change
    add_column :people, :passport_number_encrypted, :string
  end
end
