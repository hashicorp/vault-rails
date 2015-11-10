require "active_support/concern"

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
      # @option options [Symbol, Class] :serializer
      #   the name of the serializer to use (or a class)
      # @option options [Proc] :encode
      #   a proc to encode the value with
      # @option options [Proc] :decode
      #   a proc to decode the value with
      def vault_attribute(attribute, options = {})
        encrypted_column = options[:encrypted_column] || "#{attribute}_encrypted"
        path = options[:path] || "transit"
        key = options[:key] || "#{Vault::Rails.application}_#{table_name}_#{attribute}"

        # Sanity check options!
        _vault_validate_options!(options)

        # Get the serializer if one was given.
        serializer = options[:serialize]

        # Unless a class or module was given, construct our serializer. (Slass
        # is a subset of Module).
        if serializer && !serializer.is_a?(Module)
          serializer = Vault::Rails.serializer_for(serializer)
        end

        # See if custom encoding or decoding options were given.
        if options[:encode] && options[:decode]
          serializer = Class.new
          serializer.define_singleton_method(:encode, &options[:encode])
          serializer.define_singleton_method(:decode, &options[:decode])
        end

        # Getter
        define_method("#{attribute}") do
          instance_variable_get("@#{attribute}")
        end

        # Setter
        define_method("#{attribute}=") do |value|
          # If the currently set value is not the same as the given value (or
          # not set at all), update the instance variable and mark it as dirty.
          if instance_variable_get("@#{attribute}") != value
            attribute_will_change!("#{attribute}")
            instance_variable_set("@#{attribute}", value)
          end

          # Return the value to be consistent with other AR methods.
          value
        end

        # Checker
        define_method("#{attribute}?") do
          instance_variable_get("@#{attribute}").present?
        end

        # Dirty method
        define_method("#{attribute}_change") do
          changes["#{attribute}"]
        end

        # Dirty method
        define_method("#{attribute}_changed?") do
          changed.include?("#{attribute}")
        end

        # Dirty method
        define_method("#{attribute}_was") do
          if changes["#{attribute}"]
            changes["#{attribute}"][0]
          else
            public_send("#{attribute}")
          end
        end

        # Make a note of this attribute so we can use it in the future (maybe).
        __vault_attributes[attribute.to_sym] = {
          key: key,
          path: path,
          serializer: serializer,
          encrypted_column: encrypted_column,
        }

        self
      end

      # The list of Vault attributes.
      #
      # @return [Hash]
      def __vault_attributes
        @vault_attributes ||= {}
      end

      # Validate that Vault options are all a-okay! This method will raise
      # exceptions if something does not make sense.
      def _vault_validate_options!(options)
        if options[:serializer]
          if options[:encode] || options[:decode]
            raise Vault::Rails::ValidationFailedError, "Cannot use a " \
              "custom encoder/decoder if a `:serializer' is specified!"
          end
        end

        if options[:encode] && !options[:decode]
          raise Vault::Rails::ValidationFailedError, "Cannot specify " \
            "`:encode' without specifying `:decode' as well!"
        end

        if options[:decode] && !options[:encode]
          raise Vault::Rails::ValidationFailedError, "Cannot specify " \
            "`:decode' without specifying `:encode' as well!"
        end
      end
    end

    included do
      # After a resource has been found (since `after_initialize` does not make
      # sense because new resources will not have Vault data), immediately
      # communicate with Vault and decrypt the attributes (if any).
      # after_find :__vault_load_attributes!
      after_find :__vault_load_attributes!

      # Persist any changed attributes back to Vault before saving the record.
      before_save :__vault_persist_attributes!

      # After we save the record, reload the attributes from Vault to ensure
      # we have the proper attribute set.
      after_save :__vault_load_attributes!

      # Decrypt all the attributes from Vault.
      # @return [true]
      def __vault_load_attributes!
        self.class.__vault_attributes.each do |attribute, options|
          self.__vault_load_attribute!(attribute, options)
        end

        return true
      end

      # Decrypt and load a single attribute from Vault.
      def __vault_load_attribute!(attribute, options)
        key        = options[:key]
        path       = options[:path]
        serializer = options[:serializer]
        column     = options[:encrypted_column]

        # Load the ciphertext
        ciphertext = read_attribute(column)

        # Load the plaintext value
        plaintext = Vault::Rails.decrypt(path, key, ciphertext)

        # Deserialize the plaintext value, if a serializer exists
        if serializer
          plaintext = serializer.decode(plaintext)
        end

        # Write the virtual attribute with the plaintext value
        instance_variable_set("@#{attribute}", plaintext)
      end

      # Encrypt all the attributes using Vault and set the encrypted values back
      # on this model.
      # @return [true]
      def __vault_persist_attributes!
        self.class.__vault_attributes.each do |attribute, options|
          self.__vault_persist_attribute!(attribute, options)
        end

        return true
      end

      # Encrypt a single attribute using Vault and persist back onto the
      # encrypted attribute value.
      def __vault_persist_attribute!(attribute, options)
        key        = options[:key]
        path       = options[:path]
        serializer = options[:serializer]
        column     = options[:encrypted_column]

        # Only persist changed attributes to minimize requests - this helps
        # minimize the number of requests to Vault.
        if !changed.include?("#{attribute}")
          return
        end

        # Get the current value of the plaintext attribute
        plaintext = instance_variable_get("@#{attribute}")

        # Apply the serialize to the plaintext value, if one exists
        if serializer
          plaintext = serializer.encode(plaintext)
        end

        # Generate the ciphertext and store it back as an attribute
        ciphertext = Vault::Rails.encrypt(path, key, plaintext)
        write_attribute(column, ciphertext)
      end

      # Override the reload method to reload the Vault attributes. This will
      # ensure that we always have the most recent data from Vault when we
      # reload a record from the database.
      def reload(*)
        super.tap do
          self.__vault_load_attributes!
        end
      end
    end
  end
end
