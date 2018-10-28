<<<<<<< 132e351f918e3a32e2c8c730b186b88104cedfb3
class CreatePeople < ActiveRecord::Migration[4.2]
=======
class CreatePeople < ActiveRecord::Migration[5.2]
>>>>>>> update rails version in dummy app to 5.2, run migrations in environment
  def change
    create_table :people do |t|
      t.string :name
      t.string :ssn_encrypted
      t.string :cc_encrypted
      t.string :details_encrypted
      t.string :business_card_encrypted
      t.string :favorite_color_encrypted
      t.string :non_ascii_encrypted
      t.string :default_encrypted
      t.string :default_with_serializer_encrypted
      t.string :context_string_encrypted
      t.string :context_symbol_encrypted
      t.string :context_proc_encrypted

      t.timestamps null: false
    end
  end
end
