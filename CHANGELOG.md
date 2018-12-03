# Vault Rails Changelog

## Unreleased

NEW FEATURES
- New serializers for `time` and `datetime`

BREAKING CHANGES
- Actually drop support for rails 4.x, we should have done this in 0.7.0

## v0.7.1 (November 21, 2018)

NEW FEATURES
- Support for batch encryption/decryption via `Vault::Rails.batch_encrypt`
  and `Vault::Rails.batch_decrypt` methods.
- Introduce deprecation warnings for the breaking changes between 0.6 and
  0.7.  This includes adding back `Vault::AttributeProxy` as an empty
  module that generates a deprecation warning.

BUG FIXES
- Actually persist encrypted attributes when using
  `vault_persist_before_save!` in rails 5.2
- Support lazy loading of `nil` values.

## v0.7.0 (October 24, 2018)

NOTABLE CHANGES
 - Use ActiveRecord Attribute API to implement encrypted attributes
 - Add support for ActiveRecord >= 5.2 and ActiveRecord < 6.0

BREAKING CHANGES
 - `vault_attribute_proxy` is included with `Vault::EncryptedModel` by
   default, there is no `Valut::AttributeProxy` module any more.
 - type information is now specified on `vault_attribute` definitions
   instead of the `vault_attribute_proxy` definitions.

## v0.6.3 (October 31, 2018)

NEW FEATURES
- Allow specifying type information on `vault_attribute_proxy` definitions.
  This allows the proxied attribute to convert between strings (what all
  values ultimately are when send to vault for encryption) and the typed
  representation that we'd otherwise get from a traditional activerecord
  database-backed attribute.

## v0.6.2 (October 30, 2018)

NEW FEATURES
- Introduce `vault_attribute_proxy` via including Vault::AttributeProxy.
  This acts to unify an existing plaintext column with a new encryped
  column defined as a `vault_attribute`.  Allowing a staged transition to
  a fully encrypted attribute at a later date.

## v0.6.1 (October 16, 2018)

NEW FEATURES
- Allow specifying encoding for decrypted values via `Vault::Rails.encoding`

BUG FIXES
- Stop relying on Rails for default encoding of decrypted values
- Use `ActiveRecord::Base.logger` instead of `Rails.logger`
- When serialising JSON values pass through nil values as nil, not `{}`

## v0.6.0 (October 15, 2018)

NOTABLE CHANGES

- Removed 4.1 dependency
- Change dependency from Rails to ActiveRecord

## v0.5.0 (October 9, 2018)
NEW FEATURES
- Convergent Encryption
- New serializers
- Encrypting attributes on before_save

IMPROVEMENTS
- Improved lazy decryption

## v0.4.0 (November 9, 2017)
- Update supported Ruby and Rails versions [GH-50]
  - Ruby
    - Added 2.4.2
    - Dropped 2.1
    - Updated 2.2.x and 2.3.x families to 2.2.8 and 2.3.5 respectively
  - Rails
    - Restricted supported version to < 5.1

## v0.3.2 (May 8, 2017)

IMPROVEMENTS

- Added configuration setting for controlling appearance of warning messages about in-memory ciphers [GH-45]
- `vault-rails` is licensed under Mozilla Public License 2.0, and has been for over 2 years. This patch release updates the gemspec to use the correct SPDX ID string for reporting this license, but **no change to the licensing of this gem has occurred**. [GH-48]

## v0.3.1 (March 3, 2017)

IMPROVEMENTS

- Add ability to lazy decrypt attributes [GH-41]

## v0.3.0 (August 21, 2016)

IMPROVEMENTS

- Add support for Rail 5 and better testing matrix

BUG FIXES

- Use a pre-configured client to ensure options are inherited from the
  default client

## v0.2.0 (May 2, 2016)

BREAKING CHANGES
- The API for configuration now lives under `Vault::Rails` instead of `Vault`.
  Existing users will need to update their configuration as follows:

  ```diff
  - Vault.configure do |config|
  + Vault::Rails.configure do |config|
  ```
- Remove testing mode and use an in-memory vault store in development and test
  instead with the option to disable
- Load from Vault during initialize and save instead of on each change. This is
  not necessarily a "breaking" change, but users who were depending on the
  previous behavior of always making a call to Vault when setting attributes
  will experience a break. However, the new approach significantly reduces the
  load on the Vault cluster.

IMPROVEMENTS

- Allow specifying custom serialization options
- Add dirty tracking for Active Record models
- Unset instance variables when `reload` is called for ActiveRecord models
- Fix issues that would occur when using multiple threads
- Add support for retries

BUG FIXES

- Update documentation to better describe configuration options
- Update documentation around advanced configuration options
- Update documentation to include example Vault policies for the transit backend
- Do not attempt to read back a secret after writing to the logical backend
- Increase test coverage
- Force character encodings

## v0.1.2 (May 14, 2015)

- Do not automatically mount or create keys (security issue, see README for
  more information)
- Add testing harness

## v0.1.1 (May 13, 2015)

- Lazy-connect to Vault - this fixes a bug which would require users to run a
  local Vault installation just to get the Rails application to boot.

## v0.1.0 (April 29, 2015)

- Initial release
