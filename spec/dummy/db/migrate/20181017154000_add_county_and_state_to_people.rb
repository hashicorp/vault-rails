class AddCountyAndStateToPeople < ActiveRecord::Migration[5.0]
  def change
    add_column :people, :county, :string
    add_column :people, :county_encrypted, :string

    add_column :people, :state, :string
    add_column :people, :state_encrypted, :string
  end
end

