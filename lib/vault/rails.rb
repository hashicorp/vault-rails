require "vault"

require "base64"
require "json"

module Vault
  class << self
    # The name of this application.
    #
    # @return [String]
    attr_writer :application

    # The name of the application. This must be set or an error will be
    # returned.
    #
    # @return [String]
    def application
      if !defined?(@application) || @application.nil?
        raise RuntimeError, "Must set `Vault.application'!"
      end

      return @application
    end
  end

  autoload :EncryptedModel, "vault/encrypted_model"

  module Rails
    # Encrypt the given plaintext data using the provided mount and key.
    #
    # @param [String] path
    #   the mount point
    # @param [String] key
    #   the key to encrypt at
    # @param [String] plaintext
    #   the plaintext to encrypt
    #
    # @return [String]
    #   the encrypted cipher text
    def self.encrypt(path, key, plaintext)
      route  = File.join(path, "encrypt", key)
      secret = Vault.logical.write(route,
        plaintext: Base64.strict_encode64(plaintext),
      )
      return secret.data[:ciphertext]
    end

    # Decrypt the given ciphertext data using the provided mount and key.
    #
    # @param [String] path
    #   the mount point
    # @param [String] key
    #   the key to decrypt at
    # @param [String] ciphertext
    #   the ciphertext to decrypt
    #
    # @return [String]
    #   the decrypted plaintext text
    def self.decrypt(path, key, ciphertext)
      route  = File.join(path, "decrypt", key)
      secret = Vault.logical.write(route, ciphertext: ciphertext)
      return Base64.strict_decode64(secret.data[:plaintext])
    end
  end
end
