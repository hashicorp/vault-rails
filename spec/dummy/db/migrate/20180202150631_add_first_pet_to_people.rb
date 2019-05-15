class AddFirstPetToPeople < ActiveRecord::Migration
  def change
    add_column :people, :first_pet_encrypted, :string
  end
end
