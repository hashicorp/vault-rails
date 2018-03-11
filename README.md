Vault Rails [![Build Status](https://secure.travis-ci.org/hashicorp/vault-rails.svg?branch=master)](http://travis-ci.org/hashicorp/vault-rails)
===========

Vault is the official Rails plugin for interacting with [Vault](https://vaultproject.io) by HashiCorp.

**The documentation in this README corresponds to the master branch of the Vault Rails plugin. It may contain unreleased features or different APIs than the most recently released version. Please see the Git tag that corresponds to your version of the Vault Rails plugin for the proper documentation.**

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
      # Use Vault in transit mode for encrypting and decrypting data. If
      # disabled, vault-rails will encrypt data in-memory using a similar
      # algorithm to Vault. The in-memory store uses a predictable encryption
      # which is great for development and test, but should _never_ be used in
      # production.
      vault.enabled = Rails.env.production?

      # The name of the application. All encrypted keys in Vault will be
      # prefixed with this application name. If you change the name of the
      # application, you will need to migrate the encrypted data to the new
      # key namespace.
      vault.application = "my_app"

      # The address of the Vault server. Default: ENV["VAULT_ADDR"].
      vault.address = "https://vault.corp"

      # The token to communicate with the Vault server.
      # Default: ENV["VAULT_TOKEN"].
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


Advanced Configuration
----------------------
The following section details some of the more advanced configuration options for vault-rails. As a general rule, you should try to use vault-rails without these options until absolutely necessary.

#### Specifying the encrypted column
By default, the name of the encrypted column is `#{column}_encrypted`. This is customizable by setting the `:encrypted_column` option when declaring the attribute:

```ruby
vault_attribute :credit_card,
  encrypted_column: :cc_encrypted
```

- **Note** Changing this value for an existing application will make existing values no longer decryptable!
- **Note** This value **cannot** be the same name as the vault attribute!

#### Specifying a custom key
By default, the name of the key in Vault is `#{app}_#{table}_#{column}`. This is customizable by setting the `:key` option when declaring the attribute:

```ruby
vault_attribute :credit_card,
  key: "pci-data"
```

- **Note** Changing this value for an existing application will make existing values no longer decryptable!

#### Specifying a different Vault path
By default, the path to the transit backend in Vault is `transit/`. This is customizable by setting the `:path` option when declaring the attribute:

```ruby
vault_attribute :credit_card,
  path: "transport"
```

- **Note** Changing this value for an existing application will make existing values no longer decryptable!

#### Automatic serializing
By default, all values are assumed to be "text" fields in the database. Sometimes it is beneficial for your application to work with a more flexible data structure (such as a Hash or Array). Vault-rails can automatically serialize and deserialize these structures for you:

```ruby
vault_attribute :details
  serialize: :json
```

- **Note** You can view the source for the exact serialization and deserialization options, but they are intentionally not customizable and cannot be used for a full object marshal/unmarshal.

For customized solutions, you can also pass a module to the `:serializer` key. This module must have the following API:

```ruby
module MySerializer
  # @param [String, nil] raw
  # @return [String, nil]
  def self.encode(raw); end

  # @param [String, nil] raw
  # @return [String, nil]
  def self.decode(raw); end
end
```

Your class must account for `nil` and "empty" values if necessary. Then specify the class as the serializer:

```ruby
vault_attribute :details,
  serialize: MySerializer
```

- **Note** It is possible to encode and decode entire Ruby objects using a custom serializer. Please do not do that. You will have a bad time.

#### Custom encoding/decoding
If a custom serializer seems too heavy, you can declare an `:encode` and `:decode` proc when declaring the attribute. Both options must be given:

```ruby
vault_attribute :address,
  encode: ->(raw) { raw.to_s.upcase },
  decode: ->(raw) { raw.to_s }
```

- **Note** Changing the algorithm for encoding/decoding for an existing application will probably make the application crash when attempting to retrieve existing values!

Caveats
-------

### Mounting/Creating Keys in Vault
The Vault Rails plugin does not automatically mount a backend. It is assumed the proper backend is mounted and accessible by the given token. You can mount a transit backend like this:

```shell
$ vault mount transit
```

If you are running Vault 0.2.0 or later, the Vault Rails plugin will automatically create keys in the transit backend if it has permission. Here is an example policy to grant permissions:

```javascript
# Allow renewal of leases for secrets
path "sys/renew/*" {
  policy = "write"
}

# Allow renewal of token leases
path "auth/token/renew/*" {
  policy = "write"
}

path "transit/encrypt/myapp_*" {
  policy = "write"
}

path "transit/decrypt/myapp_*" {
  policy = "write"
}
```

Note that you will need to have an out-of-band process to renew your Vault token.

For lower versions of Vault, the Vault Rails plugin does not automatically create transit keys in Vault. Instead, you should create keys for each column you plan to encrypt using a different policy, out-of-band from the Rails application. For example:

```shell
$ vault write transit/keys/<key> create=1
```

Unless customized, the name of the key will always be:

    <app>_<table>_<column>

So for the example above, the key would be:

    my_app_people_ssn


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
