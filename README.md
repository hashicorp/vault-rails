Vault Rails
===========
[![Build Status](https://secure.travis-ci.org/hashicorp/vault-rails.png?branch=master)](http://travis-ci.org/hashicorp/vault-rails)

Vault is the official Rails plugin for interacting with [Vault](https://vaultproject.io) by HashiCorp.


Quick Start
-----------
1. Add to your Gemfile:

    ```ruby
    gem "vault-rails", "~> 0.1", require: false
    ```

    and then run the `bundle` command to install.

1. Create an initializer:

    ```ruby
    require "vault/rails"

    Vault::Rails.configure do |vault|
      vault.application = "my_app"

      # Default: ENV["VAULT_ADDR"]
      vault.address = "https://vault.corp"

      # Default: ENV["VAULT_TOKEN"]
      vault.token = "abcd1234"
    end
    ```

    For more customization, such as custom SSL certificates, please see the
    [Vault Ruby documentation](https://github.com/hashicorp/vault-ruby).

1. Add Vault to the model you want to encrypt:

    ```ruby
    class Person < ActiveRecord::Base
      include Vault::EncryptedModel
      vault_attribute :ssn
    end
    ```

    Each attribute you want to encrypt must have a corresponding `attribute_encrypted` column in the database. For the above example:


    ```ruby
    class AddEncryptedSSNToPerson < ActiveRecord::Migration
      add_column :persons, :ssn_encrypted, :string
    end
    ```

    That is it! The plugin will transparently handle the encryption and decryption of secrets with Vault:

    ```ruby
    person = Person.new
    person.ssn = "123-45-6789"
    person.save #=> true
    person.ssn_encrypted #=> "vault:v0:EE3EV8P5hyo9h..."
    ```

    You can customize the `vault_attribute` method with the following options:

    ```ruby
    vault_attribute :credit_card,
      encrypted_column: :cc_encrypted,
      path: "credit-secrets",
      key: "people_credit_cards"
    ```

    - `:encrypted_column` - the name of the encrypted column
      (default: `attribute_encrypted`)
    - `:key` - the name of the key
      (default: `#{app}_#{table}_#{column}`)
    - `:path` - the path to the transit backend to use
      (default: `transit/`)

Caveats
-------

### Searching Encrypted Attributes
Because each column is uniquely encrypted, it is not possible to search for a
particular plain-text value. For example, if the `ssn` attribute is encrypted,
the following will **NOT** work:

```ruby
Person.where(ssn: "123-45-6789")
```

This is because the database is unaware of the plain-text data (which is part of
the security model).


Development
-----------
1. Clone the project on GitHub
2. Create a feature branch
3. Submit a Pull Request

Important Notes:

- **All new features must include test coverage.** At a bare minimum, Unit tests are required. It is preferred if you include acceptance tests as well.
- **The tests must be be idempotent.** The HTTP calls made during a test should be able to be run over and over.
- **Tests are order independent.** The default RSpec configuration randomizes the test order, so this should not be a problem.
