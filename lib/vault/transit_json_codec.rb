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

    def decrypt(ciphertext)
      return if ciphertext.blank?

      secret = Vault.logical.write(
        "transit/decrypt/#{key}",
        ciphertext: ciphertext
      )

      Oj.load(Base64.strict_decode64(secret.data[:plaintext]))
    end

    private

    attr_reader :key
  end
end
