# encoding: utf-8

require "spec_helper"

RSpec.describe './bin/rake db:create' do
  it "works == the code doesn't need a database to load" do
    db_file = File.join(dummy_root, 'db/rails_db_create_spec.sqlite3')

    File.delete(db_file) if File.exist?(db_file)

    command = [
      'RAILS_ENV=development',
      'FC_VAULT_RAILS_DUMMY_DATABASE_PATH="db/rails_db_create_spec.sqlite3"',
      "FC_VAULT_RAILS_DUMMY_VAULT_SERVER='#{RSpec::VaultServer.address}'",
      "FC_VAULT_RAILS_DUMMY_VAULT_TOKEN='#{RSpec::VaultServer.token}'",
      "#{dummy_root}/bin/rails runner 'puts TypedPerson.class'"
    ]

    `#{command.join(' ')}`

    # If the file exists it means that rails tried to connect to the database
    expect(File.exist?(db_file)).to eq(false)
  end
end
