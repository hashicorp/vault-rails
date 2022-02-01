Vault Rails [![CircleCI](https://circleci.com/gh/FundingCircle/vault-rails/tree/master.svg?style=svg)](https://circleci.com/gh/FundingCircle/vault-rails/tree/master)
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
By default, the name of the key in Vault is `#{app}_#{table}_#{column}`. This is customizable by setting the `:key` coption when declaring the attribute:

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

#### Attribute types
The latest version of VaultRails uses ActiveRecord's Attribute API to implement encrypted attributes. This allows us to use its's internal type casting mechanism, and makes encrypted attributes behave like normal ActiveRecord ones. If you don't specify a type, the default is ActiveRecord::Type::Value, which can hold any value.

Since Vault ciphertexts are always Base64 encoded strings, we still need to tell ActiveRecord how to handle this. ActiveRecord knows how to convert between ruby objects and datatypes that the database understands, but this is not useful to us in this case. There are a number of ways to deal with this:
 * use serializers
 * use `encode`/`decode` procs
 * Define your own types (inherit from `ActiveRecord::Type::Value`) and override the `type_cast_from_database`/`type_cast_for_database` (AR 4.2) or `serialize`/`deserialize` (AR 5+)

```ruby
class User < ActiveRecord::Base
  include Vault::EncryptedModel
  vault_attribute :date_of_birth,
    type: :date,
    encode: -> (raw) { raw.to_s if raw },
    decode: -> (raw) { raw.to_date if raw }
end

>> user = User.new
=> #<User:0x0000...>
>> user.date_of_birth = '1988-10-15'
=> "1988-10-15"
>> user.date_of_birth.class
=> Date
```

#### Automatic serializing
By default, all values are assumed to be "text" fields in the database. Sometimes it is beneficial for your application to work with a more flexible data structure (such as a Hash or Array). Vault-rails can automatically serialize and deserialize these structures for you:

```ruby
vault_attribute :details
  serialize: :json
```

This is the list of included serializers:
 * `:json`
 * `:date`
 * `:integer`
 * `:float`

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

- **Note** Changing the algorithm for encoding/decoding for an existing application will probably make the application crash when attempting to retrive existing values!

### Lazy Decryption
VaultRails decrypts all the encrypted attributes in an `after_initialize` callback. Although this is useful sometimes, other times it may be unnecessary. For example you may not need all or any of the encrypted attributes.
In such cases, you can use `vault_lazy_decrypt!` in your model, and VaultRails will decrypt the attributes, one by one, only when they are needed.

Caveats
-------

### Saving encrypted attributes
By default, VaultRails will encrypt and then save the encrypted attributes in an `after_save` callback. This results in a second query to the database. If you'd like to avoid this and encrypt the attributes before the model is saved, you can use `vault_persist_before_save!` in your model, and it will encrypt the attribues in a `before_save` callback.

-- **Note** You'll need to make sure that no other callbacks interfere with these callbacks e.g. (modify the ciphertext).

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


### Convergent Encryption
Convergent encryption is a mode where the same set of plaintext and context always result in the same ciphertext. It does this by deriving a key using a key derivation function but also by deterministically deriving a nonce. You can use this if you need to check for uniqueness, or if you need the ability to search (exact-match).

Vault supports convergent encryption since v0.6.1. We take advantage of this functionality.

You'll need to provide an encryption context for the key derivation function in order to use convergent encryption.
```ruby
Vault::Rails.configure do |vault|
  vault.convergent_encryption_context = ENV['CONVERGENT_ENCRYPTION_CONTEXT']
end
```

Then, you can tell Vault to use convergent encryption like so:
```ruby
vault_attribute :ssn,
  convergent: true
```

- **Note** Convergent encryption significantly weakens the security that encryption provides. Use this with caution!

### Batch encryption and decryption
There is an option to encrypt or decrypt multiple strings at once.
All items to be encrypted/decrypted should use the same path, key and client.

``` ruby
Vault::Rails.batch_decrypt(path, key, <array of ciphertexts>, client)
Vault::Rails.batch_encrypt(path, key, <array of plaintexts>, client)
```

Even easier, you could use:

* ```EncryptedModel.vault_persist_all(attribute, records, plaintexts, validate: true)```

  Encrypt all plaintext values and save them as the given attribute for the corresponding record
  If you pass `validate: false` to `vault_persist_all` objects will be saved without validations. By default, validations are turned on.

* ```EncryptedModel.vault_load_all(attribute, records)```

  Decrypt and load the given attribute for each of the records



### Searching Encrypted Attributes
Because each column is uniquely encrypted, it is not possible to search for a
particular plain-text value with a plain `ActiveRecord` query. For example, if the `ssn` attribute is encrypted,
the following will **NOT** work:

```ruby
Person.where(ssn: "123-45-6789")
```

That's why we have added a method that provides an easy to use search interface. Instead of using `.where` you can use
`.encrypted_where`. Example:

```ruby
Person.encrypted_where(driving_licence_number: '12345678')
```

This method will look up seamlessly in the relevant column with encrypted data.
It is important to note that you can search only for attributes with **convergent** encryption.
Similar to `.where` the method `.encrypted_where` also returns an `ActiveRecord::Relation`

Along with `.encrypted_where` we also have `.encrypted_where_not` which finds encrypted records not matching the specified conditions acts like `.where.not`

There is also `.encrypted_find_by` which works like `.find_by` finds the first encrypted record matching the specified conditions.

```ruby
Personal.encrypted_find_by(driving_licence_number: '12345678')
```

and `.encrypted_find_by!` like `encrypted_find_by`, except that if no record is found, raises an `ActiveRecord::RecordNotFound` error.

```ruby
Personal.encrypted_find_by!(driving_licence_number: '12345678')
```

### Uniqueness Validation
If a column is **convergently** encrypted, it is possible to add a validation of uniqueness to it.
Example:
```ruby
validates :driving_licence_number, vault_uniqueness: true
```

It is highly advisable that you also add a uniqueness constraint at database level.

### Vault Attribute Proxy
This method is useful if you have a plaintext attribute that you want to replace with a vault attribute.
During a transition period both attributes can be seamlessly read/changed at the same time.
Then by using the boolean option `encrypted_attribute_only`, you will be able to test if the ciphertext field works as expected before getting rid of the plaintext attribute.
In order to use this method for an attribute you need to add the following row in your model for given plaintext and ciphertext attributes:
```ruby
vault_attribute_proxy :attribute, :attribute_ciphertext, encrypted_attribute_only: true
```

Upgrading to the latest version from 0.6.x
-------------------------

Master now targets both rails 4.2.x and rails 5.x. There are breaking changes between the two versions too, so upgrading isn't as smooth as it could be.

1. You no longer need to `include Vault::AttributeProxy` to get `vault_attribute_proxy` as it is part of `Vault::EncryptedModel` now in both versions.

    **If you do nothing** your app will still work properly in master, but you'll get annoying messages.

2. Passing a type as an object is no longer supported `type: ActiveRecord::Type::Time.new` if you need to use a `ActiveRecord::Type` pass it as a symbol e.g. `type: :time`.

Development
-----------
1. Clone the project on GitHub
2. Create a feature branch
3. Submit a Pull Request

Important Notes:

- **All new features must include test coverage.** At a bare minimum, Unit tests are required. It is preferred if you include acceptance tests as well.
- **The tests must be be idempotent.** The HTTP calls made during a test should be able to be run over and over.
- **Tests are order independent.** The default RSpec configuration randomizes the test order, so this should not be a problem.

We now have two versions of `Vault::EncryptedModel` a `Latest` version which targets rails 5.x and up and a `Legacy` version which targets 4.2.x. It made sense to keep these two version seperate from one another because of the amount of differences between them. So if changes need to be applied to support both versions both files must be changed.

Getting tests to run
--------------------
```
$ bundle exec rake db:schema:load
```
