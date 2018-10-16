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
      # @option options [Bool] :convergent
      #   use convergent encryption (default: +false+)
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
      def vault_attribute(attribute_name, options = {})
        encrypted_column = options[:encrypted_column] || "#{attribute_name}_encrypted"
        path = options[:path] || "transit"
        key = options[:key] || "#{Vault::Rails.application}_#{table_name}_#{attribute_name}"
        convergent = options.fetch(:convergent, false)

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

        attribute_type = options.fetch(:type, :value)

        if attribute_type.is_a?(Symbol)
          constant_name = attribute_type.to_s.camelize

          unless ActiveRecord::Type.const_defined?(constant_name)
            raise RuntimeError, "Unrecognized attribute type `#{attribute_type}`!"
          end

          attribute_type = ActiveRecord::Type.const_get(constant_name).new
        end

        # Attribute API
        attribute(attribute_name, attribute_type)

        # Getter
        define_method(attribute_name) do
          read_attribute(attribute_name) || __vault_load_attribute!(attribute_name, self.class.__vault_attributes[attribute_name])
        end

        # Setter
        define_method("#{attribute_name}=") do |value|
          # Force the update of the attribute, to be consistent with old behaviour
          attribute_will_change!(attribute_name)
          write_attribute(attribute_name, value)
        end

        # Make a note of this attribute so we can use it in the future (maybe).
        __vault_attributes[attribute_name.to_sym] = {
          key: key,
          path: path,
          serializer: serializer,
          encrypted_column: encrypted_column,
          convergent: convergent
        }

        self
      end

      # Encrypt Vault attribures before saving them
      def vault_persist_before_save!
        skip_callback :save, :after, :__vault_persist_attributes!
        before_save :__vault_encrypt_attributes!
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

      def vault_lazy_decrypt?
        !!@vault_lazy_decrypt
      end

      def vault_lazy_decrypt!
        @vault_lazy_decrypt = true
      end
    end

    included do
      # After a resource has been initialized, immediately communicate with
      # Vault and decrypt any attributes unless vault_lazy_decrypt is set.
      after_initialize :__vault_load_attributes!

      # After we save the record, persist all the values to Vault and reload
      # them attributes from Vault to ensure we have the proper attributes set.
      # The reason we use `after_save` here is because a `before_save` could
      # run too early in the callback process. If a user is changing Vault
      # attributes in a callback, it is possible that our callback will run
      # before theirs, resulting in attributes that are not persisted.
      after_save :__vault_persist_attributes!

      # Decrypt all the attributes from Vault.
      def __vault_load_attributes!
        return if self.class.vault_lazy_decrypt?

        self.class.__vault_attributes.each do |attribute, options|
          self.__vault_load_attribute!(attribute, options)
        end
      end

      # Decrypt and load a single attribute from Vault.
      def __vault_load_attribute!(attribute, options)
        # If the user provided a value for the attribute, do not try to load it from Vault
        return unless read_attribute(attribute).nil?

        key        = options[:key]
        path       = options[:path]
        serializer = options[:serializer]
        column     = options[:encrypted_column]
        convergent = options[:convergent]

        # Load the ciphertext
        ciphertext = read_attribute(column)

        # Load the plaintext value
        plaintext = Vault::Rails.decrypt(path, key, ciphertext, Vault.client, convergent)

        # Deserialize the plaintext value, if a serializer exists
        plaintext = serializer.decode(plaintext) if serializer

        # Write the virtual attribute with the plaintext value
        write_attribute(attribute, plaintext)
      end

      # Encrypt all the attributes using Vault and set the encrypted values back
      # on this model.
      # @return [true]
      def __vault_persist_attributes!
        changes = __vault_encrypt_attributes!

        # If there are any changes to the model, update them all at once,
        # skipping any callbacks and validation. This is okay, because we are
        # already in a transaction due to the callback.
        self.update_columns(changes) if !changes.empty?

        true
      end

      def __vault_encrypt_attributes!
        changes = {}

        self.class.__vault_attributes.each do |attribute, options|
          if c = self.__vault_encrypt_attribute!(attribute, options)
            changes.merge!(c)
          end
        end

        changes
      end

      # Encrypt a single attribute using Vault and persist back onto the
      # encrypted attribute value.
      def __vault_encrypt_attribute!(attribute, options)
        # Only persist changed attributes to minimize requests - this helps
        # minimize the number of requests to Vault.
        return unless changed.include?("#{attribute}")

        key        = options[:key]
        path       = options[:path]
        serializer = options[:serializer]
        column     = options[:encrypted_column]
        convergent = options[:convergent]

        # Get the current value of the plaintext attribute
        plaintext = read_attribute(attribute)

        # Apply the serialize to the plaintext value, if one exists
        if serializer
          plaintext = serializer.encode(plaintext)
        end

        # Generate the ciphertext and store it back as an attribute
        ciphertext = Vault::Rails.encrypt(path, key, plaintext, Vault.client, convergent)

        # Write the attribute back, so that we don't have to reload the record
        # to get the ciphertext
        write_attribute(column, ciphertext)

        # Return the updated column so we can save
        { column => ciphertext }
      end

      # Override the reload method to reload the Vault attributes. This will
      # ensure that we always have the most recent data from Vault when we
      # reload a record from the database.
      def reload(*)
        super.tap do
          # Unset all attributes to force the new data to be pulled from Vault
          self.class.__vault_attributes.each do |attribute, _|
            write_attribute(attribute, nil)
          end

          self.__vault_load_attributes!
          clear_changes_information
        end
      end
    end
  end
end
