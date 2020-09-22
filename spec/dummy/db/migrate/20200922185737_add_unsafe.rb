class AddUnsafe < ActiveRecord::Migration[6.0]
  def change
    add_column :people, :unsafe, :string
    add_column :people, :unsafe_encrypted, :string
  end
end
