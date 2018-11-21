require 'vault'

require 'base64'
require 'json'

require_relative 'encrypted_model'
require_relative 'attribute_proxy'
require_relative 'rails/configurable'
require_relative 'rails/errors'
require_relative 'rails/serializers/json_serializer'
require_relative 'rails/serializers/date_serializer'
require_relative 'rails/serializers/integer_serializer'
require_relative 'rails/serializers/float_serializer'
require_relative 'rails/version'

module Vault
  module Rails
    # The list of serializers.
    #
    # @return [Hash<Symbol, Module>]
    SERIALIZERS = {
      json:     Vault::Rails::Serializers::JSONSerializer,
      date:     Vault::Rails::Serializers::DateSerializer,
      integer:  Vault::Rails::Serializers::IntegerSerializer,
      float:    Vault::Rails::Serializers::FloatSerializer
    }.freeze

    # The warning string to print when running in development mode.
    DEV_WARNING = "[vault-rails] Using in-memory cipher - this is not secure " \
      "and should never be used in production-like environments!".freeze

    class << self
      # API client object based off the configured options in {Configurable}.
      #
      # @return [Vault::Client]
      attr_reader :client

      def setup!
        Vault.setup!

        @client = Vault.client
        @client.class.instance_eval do
          include Vault::Rails::Configurable
        end

        self
      end

      # Delegate all methods to the client object, essentially making the module
      # object behave like a {Vault::Client}.
      def method_missing(m, *args, &block)
        if client.respond_to?(m)
          client.public_send(m, *args, &block)
        else
          super
        end
      end

      # Delegating `respond_to` to the {Vault::Client}.
      def respond_to_missing?(m, include_private = false)
        client.respond_to?(m, include_private) || super
      end

      # Encrypt the given plaintext data using the provided mount and key.
      #
      # @param [String] path
      #   the mount point
      # @param [String] key
      #   the key to encrypt at
      # @param [String] plaintext
      #   the plaintext to encrypt
      # @param [Vault::Client] client
      #   the Vault client to use
      # @param [Bool] convergent
      #   use convergent encryption
      #
      # @return [String]
      #   the encrypted cipher text
      def encrypt(path, key, plaintext, client = self.client, convergent = false)
        return plaintext if plaintext.blank?

        path = path.to_s
        key  = key.to_s

        with_retries do
          if self.enabled?
            result = self.vault_encrypt(path, key, plaintext, client, convergent)
          else
            result = self.memory_encrypt(path, key, plaintext, client, convergent)
          end

          return self.force_encoding(result)
        end
      end

      # works only with convergent encryption
      def batch_encrypt(path, key, plaintexts, client = self.client)
        return [] if plaintexts.empty?

        path = path.to_s
        key = key.to_s

        with_retries do
          results = if self.enabled?
                      self.vault_batch_encrypt(path, key, plaintexts, client)
                    else
                      self.memory_batch_encrypt(path, key, plaintexts, client)
                    end

          results.map { |result| self.force_encoding(result) }
        end
      end

      # Decrypt the given ciphertext data using the provided mount and key.
      #
      # @param [String] path
      #   the mount point
      # @param [String] key
      #   the key to decrypt at
      # @param [String] ciphertext
      #   the ciphertext to decrypt
      # @param [Vault::Client] client
      #   the Vault client to use
      #
      # @return [String]
      #   the decrypted plaintext text
      def decrypt(path, key, ciphertext, client = self.client, convergent = false)
        if ciphertext.blank?
          return ciphertext
        end

        path = path.to_s
        key  = key.to_s

        with_retries do
          if self.enabled?
            result = self.vault_decrypt(path, key, ciphertext, client, convergent)
          else
            result = self.memory_decrypt(path, key, ciphertext, client, convergent)
          end

          return self.force_encoding(result)
        end
      end

      # works only with convergent encryption
      def batch_decrypt(path, key, ciphertexts, client = self.client)
        return [] if ciphertexts.empty?

        path = path.to_s
        key = key.to_s

        with_retries do
          results = if self.enabled?
                      self.vault_batch_decrypt(path, key, ciphertexts, client)
                    else
                      self.memory_batch_decrypt(path, key, ciphertexts, client)
                    end

          results.map { |result| self.force_encoding(result) }
        end
      end

      # Get the serializer that corresponds to the given key. If the key does not
      # correspond to a known serializer, an exception will be raised.
      #
      # @param [#to_sym] key
      #   the name of the serializer
      #
      # @return [~Serializer]
      def serializer_for(key)
        key = key.to_sym if !key.is_a?(Symbol)

        if serializer = SERIALIZERS[key]
          return serializer
        else
          raise Vault::Rails::Serializers::UnknownSerializerError.new(key)
        end
      end

      protected

      # Perform in-memory encryption. This is useful for testing and development.
      def memory_encrypt(path, key, plaintext, _client, convergent)
        log_warning(DEV_WARNING) if self.in_memory_warnings_enabled?

        return nil if plaintext.nil?

        cipher = OpenSSL::Cipher::AES.new(128, :CBC)
        cipher.encrypt
        cipher.key = memory_key_for(path, key)

        iv = if convergent
               cipher.iv = Vault::Rails.convergent_encryption_context.first(16)
             else
               cipher.random_iv
             end

        Base64.strict_encode64(iv + cipher.update(plaintext) + cipher.final)
      end

      # Perform in-memory encryption. This is useful for testing and development.
      def memory_batch_encrypt(path, key, plaintexts, _client)
        plaintexts.map { |plaintext| memory_encrypt(path, key, ciphertext, _client, true) }
      end

      # Perform in-memory decryption. This is useful for testing and development.
      def memory_decrypt(path, key, ciphertext, _client, convergent)
        log_warning(DEV_WARNING) if self.in_memory_warnings_enabled?

        return nil if ciphertext.nil?

        cipher = OpenSSL::Cipher::AES.new(128, :CBC)
        cipher.decrypt
        cipher.key = memory_key_for(path, key)

        ciphertext_bytes = Base64.strict_decode64(ciphertext)

        cipher.iv = ciphertext_bytes.first(16)
        ciphertext = ciphertext_bytes[16..-1]

        cipher.update(ciphertext) + cipher.final
      end

      def memory_batch_decrypt(path, key, ciphertexts, _client)
        ciphertexts.map { |ciphertext| memory_decrypt(path, key, ciphertext, _client, true) }
      end


      # Perform encryption using Vault. This will raise exceptions if Vault is
      # unavailable.
      def vault_encrypt(path, key, plaintext, client, convergent)
        return nil if plaintext.nil?

        route = File.join(path, 'encrypt', key)
        options = {
          plaintext: Base64.strict_encode64(plaintext)
        }

        if convergent
          options.merge!(
            context: Base64.strict_encode64(Vault::Rails.convergent_encryption_context),
            convergent_encryption: true,
            derived: true
          )
        end

        secret = client.logical.write(route, options)
        secret.data[:ciphertext]
      end

      def vault_batch_encrypt(path, key, plaintexts, client)
        return [] if plaintexts.empty?

        route = File.join(path, 'encrypt', key)

        options = {
          convergent_encryption: true,
          derived: true
        }

        batch_input = plaintexts.map do |plaintext|
          {
            context: Base64.strict_encode64(Vault::Rails.convergent_encryption_context),
            plaintext: Base64.strict_encode64(plaintext)
          }
        end

        options.merge!(batch_input: batch_input)

        secret = client.logical.write(route, options)
        secret.data[:batch_results].map { |result| result[:ciphertext] }
      end

      # Perform decryption using Vault. This will raise exceptions if Vault is
      # unavailable.
      def vault_decrypt(path, key, ciphertext, client, convergent)
        return nil if ciphertext.nil?

        options = { ciphertext: ciphertext }

        if convergent
          options.merge!(
            context: Base64.strict_encode64(Vault::Rails.convergent_encryption_context)
          )
        end

        route  = File.join(path, 'decrypt', key)
        secret = client.logical.write(route, options)

        Base64.strict_decode64(secret.data[:plaintext])
      end

      def vault_batch_decrypt(path, key, ciphertexts, client)
        return [] if ciphertexts.empty?

        route = File.join(path, 'decrypt', key)


        batch_input = ciphertexts.map do |ciphertext|
          {
            context: Base64.strict_encode64(Vault::Rails.convergent_encryption_context),
            ciphertext: ciphertext
          }
        end

        options = { batch_input: batch_input }

        secret = client.logical.write(route, options)
        secret.data[:batch_results].map { |result| Base64.strict_decode64(result[:plaintext]) }
      end

      # The symmetric key for the given params.
      # @return [String]
      def memory_key_for(path, key)
        return Base64.strict_encode64("#{path}/#{key}".ljust(16, "x")).byteslice(0..15)
      end

      # Forces the encoding into the default encoding and returns the
      # newly encoded string.
      # @return [String]
      def force_encoding(str)
        str.force_encoding(Vault::Rails.encoding).encode(Vault::Rails.encoding)
      end

      private

      def with_retries(client = self.client, &block)
        exceptions = [Vault::HTTPConnectionError, Vault::HTTPServerError]
        options = {
          attempts: self.retry_attempts,
          base:     self.retry_base,
          max_wait: self.retry_max_wait,
        }

        client.with_retries(*exceptions, options) do |i, e|
          if !e.nil?
            log_warning "[vault-rails] (#{i}) An error occurred when trying to " \
              "communicate with Vault: #{e.message}"
          end

          yield
        end
      end

      def log_warning(msg)
        ::ActiveRecord::Base.logger.warn { msg } if ::ActiveRecord::Base.logger
      end
    end
  end
end

Vault::Rails.setup!
