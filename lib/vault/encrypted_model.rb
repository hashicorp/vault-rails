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
        encrypted_column = options[:encrypted_column] ||= "#{column}_encrypted"
        path = options[:path] ||= "transit"
        key = options[:key] ||= "#{Vault.application}_#{table_name}_#{column}"

        class_eval <<-EOH, __FILE__, __LINE__ + 1
          def #{column}
            value = instance_variable_get(:@#{column})
            return value if !value.nil?

            ciphertext = read_attribute(:#{encrypted_column})
            return nil if ciphertext.nil?

            plaintext = Vault::Rails.decrypt("#{path}", "#{key}", ciphertext)
            instance_variable_set(:@#{column}, plaintext)
          end

          def #{column}=(plaintext)
            ciphertext = Vault::Rails.encrypt("#{path}", "#{key}", plaintext)
            write_attribute(:#{encrypted_column}, ciphertext)
            instance_variable_set(:@#{column}, plaintext)
          end

          def #{column}?
            read_attribute(:#{encrypted_column}).present?
          end
        EOH

        _vault_attributes.store(column.to_sym, options.dup)

        self
      end

      # The list of Vault attributes.
      #
      # @return [Hash]
      def _vault_attributes
        @vault_attributes ||= {}
      end
    end
  end
end
