# Vault Rails Changelog

## v0.6.0 (May 11th, 2020)

IMPROVEMENTS

- Added support for Rails 5.2+ (including 6.0+)
- Added ciphertext prefixes in development/test environments to more closely resemble production environments
- Added single-decrypt functionality to allow clients to request individual attributes rather than exposing an entire model with one call

BREAKING CHANGES

- Ciphertext prefixes may break development environments for some users. If this occurs, a restart may fix the issue. Feel free to let the maintainers know if this is not the case.

## v0.5.0 (June 20th, 2019)

IMPROVEMENTS

- Added support for Vault Transit derived keys with the `:context` option. [GH-78]
- Added a `:default` option to `vault_attribute`. [GH-83]

BREAKING CHANGES

- Dropped support for Ruby < 2.4, Rails < 4.2. [GH-79]
- Null and empty types were previously deserialized to an empty JSON object (`{}`). They will now be properly deserialized as `null`, empty string (`""`), and so on. To preserve the old behavior, add `default: {}` to JSON-serialized attributes. [GH-81]

BUG FIXES

- Fixed uniqueness of generated key for in-memory operations. [GH-80]

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
