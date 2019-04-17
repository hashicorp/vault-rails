class AddDateOfBirthToPeople < ActiveRecord::Migration[5.0]
  def change
    add_column :people, :date_of_birth, :string
    add_column :people, :date_of_birth_encrypted, :string
  end
end
