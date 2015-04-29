class CreatePeople < ActiveRecord::Migration
  def change
    create_table :people do |t|
      t.string :name
      t.string :ssn_encrypted
      t.string :cc_encrypted

      t.timestamps null: false
    end
  end
end
