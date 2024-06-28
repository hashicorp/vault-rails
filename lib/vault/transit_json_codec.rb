# frozen_string_literal: true
require 'oj'

module Vault
  class TransitJsonCodec
    def initialize(key)
      @key = key
    end

    def encrypt(plaintext)
      return if plaintext.blank?

      secret = Vault.logical.write(
        "transit/encrypt/#{key}",
        plaintext: Base64.strict_encode64(Oj.dump(plaintext))
      )

      secret.data[:ciphertext]
    end

    def batch_encrypt(plaintexts)
      return [] if plaintexts.blank?

      secrets = Vault.logical.write(
        "transit/encrypt/#{key}",
        batch_input: plaintexts.map { |plaintext| { plaintext: Base64.strict_encode64(Oj.dump(plaintext)) } }
      )

      secrets.data[:batch_results].map { |result| result[:ciphertext] }
    end

    def decrypt(ciphertext)
      return if ciphertext.blank?

      secret = Vault.logical.write(
        "transit/decrypt/#{key}",
        ciphertext: ciphertext
      )

      Oj.load(Base64.strict_decode64(secret.data[:plaintext]))
    end

    def batch_decrypt(ciphertexts)
      return [] if ciphertexts.blank?

      secret = Vault.logical.write(
        "transit/decrypt/#{key}",
        batch_input: ciphertexts.map { |ciphertext| { ciphertext: ciphertext } }
      )

      secret.data[:batch_results].map { |result| Oj.load(Base64.strict_decode64(result[:plaintext])) }
    end

    private

    attr_reader :key
  end
end
