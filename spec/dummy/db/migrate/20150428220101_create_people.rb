class CreatePeople < ActiveRecord::Migration
  def change
    create_table :people do |t|
      t.string :name
      t.string :ssn_encrypted
      t.string :cc_encrypted
      t.string :details_encrypted
      t.string :business_card_encrypted
      t.string :favorite_color_encrypted
      t.string :pet_name_encrypted

      t.timestamps null: false
    end
  end
end
