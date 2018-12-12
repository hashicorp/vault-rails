class AddDrivingLicenceNumberAndIpAddressToPeople < ActiveRecord::Migration[5.0]
  def change
    add_column :people, :driving_licence_number_encrypted, :string
    add_column :people, :ip_address_encrypted, :string
  end
end
