require_relative "../encrypted_model"

require "base64"
require "openssl"

module Vault
  module Rails
    module Testing
      # Start the vault-rails testing stubs.
      #
      # @return [self]
      def self.enable!
        @enabled = true
        return self
      end

      # Stop the vault-rails testing stubs.
      #
      # @return [self]
      def self.disable!
        @enabled = false
        return self
      end

      # Returns whether the testing library is enabled.
      #
      # @return [true, false]
      def self.enabled?
        return defined?(@enabled) ? @enabled : false
      end
    end

    # Save a reference to the original methods.
    class << self
      alias_method :encrypt_original, :encrypt
      alias_method :decrypt_original, :decrypt
    end

    # @see Vault::Rails.encrypt
    def self.encrypt(path, key, plaintext)
      if Vault::Rails::Testing.enabled?
        return nil if plaintext.nil?
        cipher = OpenSSL::Cipher::AES.new(128, :CBC)
        cipher.encrypt
        cipher.key = key_for(path, key)
        return cipher.update(plaintext) + cipher.final
      else
        return encrypt_original(path, key, plaintext)
      end
    end

    # @see Vault::Rails.decrypt
    def self.decrypt(path, key, ciphertext)
      if Vault::Rails::Testing.enabled?
        return nil if ciphertext.nil?
        cipher = OpenSSL::Cipher::AES.new(128, :CBC)
        cipher.decrypt
        cipher.key = key_for(path, key)
        return cipher.update(ciphertext) + cipher.final
      else
        return decrypt_original(path, key, ciphertext)
      end
    end

    private

    # The symmetric key for the given params.
    # @return [String]
    def self.key_for(path, key)
      return Base64.strict_encode64("#{path}/#{key}".ljust(32, "x"))
    end
  end
end
