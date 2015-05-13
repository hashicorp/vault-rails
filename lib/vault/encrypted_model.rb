module Vault
  module EncryptedModel
    extend ActiveSupport::Concern

    module ClassMethods
      # Creates an attribute that is read and written using Vault.
      #
      # @example
      #
      #   class Person < ActiveRecord::Base
      #     include Vault::EncryptedModel
      #     vault_attribute :ssn
      #   end
      #
      #   person = Person.new
      #   person.ssn = "123-45-6789"
      #   person.save
      #   person.encrypted_ssn #=> "vault:v0:6hdPkhvyL6..."
      #
      # @param [Symbol] column
      #   the column that is encrypted
      # @param [Hash] options
      #
      # @option options [Symbol] :encrypted_column
      #   the name of the encrypted column (default: +#{column}_encrypted+)
      # @option options [String] :path
      #   the path to the transit backend (default: +transit+)
      # @option options [String] :key
      #   the name of the encryption key (default: +#{app}_#{table}_#{column}+)
      def vault_attribute(column, options = {})
        encrypted_column = options[:encrypted_column] || "#{column}_encrypted"
        path = options[:path] || "transit"
        key = options[:key] || "#{Vault.application}_#{table_name}_#{column}"

        class_eval <<-EOH, __FILE__, __LINE__ + 1
          def #{column}
            value = instance_variable_get(:@#{column})
            return value if !value.nil?

            encrypted = read_attribute(:#{encrypted_column})
            return nil if encrypted.nil?

            self.class._vault_ensure_mounted!("#{path}")
            self.class._vault_ensure_key!("#{path}", "#{key}")

            path = File.join("v1", "#{path}", "decrypt", "#{key}")
            response = Vault.put(path, JSON.fast_generate(
              ciphertext: encrypted,
            ))
            secret = Vault::Secret.decode(response)
            plaintext = Base64.decode64(secret.data[:plaintext])

            instance_variable_set(:@#{column}, plaintext)
          end

          def #{column}=(value)
            self.class._vault_ensure_mounted!("#{path}")
            self.class._vault_ensure_key!("#{path}", "#{key}")

            path = File.join("v1", "#{path}", "encrypt", "#{key}")
            response = Vault.put(path, JSON.fast_generate(
              plaintext: Base64.encode64(value),
            ))
            secret = Vault::Secret.decode(response)
            ciphertext = secret.data[:ciphertext]

            write_attribute(:#{encrypted_column}, ciphertext)
            instance_variable_set(:@#{column}, value)
          end

          def #{column}?
            read_attribute(:#{encrypted_column}).present?
          end
        EOH

        _vault_attributes.store(column.to_sym, true)

        self
      end

      # The list of Vault attributes.
      #
      # @return [Hash]
      def _vault_attributes
        @vault_attributes ||= {}
      end

      # Ensure the proper transit backend is mounted at the given path.
      #
      # @return [true]
      def _vault_ensure_mounted!(path)
        @_vault_mounts ||= {}
        return true if @_vault_mounts.key?(path)

        mounts = Vault.sys.mounts
        if mounts[path.to_s.chomp("/").to_sym]
          @_vault_mounts[path] = true
          return true
        end

        Vault.sys.mount(path, :transit)
        @_vault_mounts[path] = true
        return true
      end

      # Ensure a key exists for the transit backend at the given path.
      #
      # @return [true]
      def _vault_ensure_key!(path, key)
        @_vault_keys ||= {}

        key_path = File.join("v1", path, "keys", key)
        return true if @_vault_keys.key?(key_path)

        begin
          Vault.get(key_path)
        rescue => e
          raise if e.code != 404
          Vault.post(key_path, nil)
          @_vault_keys[key_path] = true
        end

        return true
      end
    end
  end
end
