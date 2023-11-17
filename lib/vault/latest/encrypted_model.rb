require "active_support/concern"
require "active_record"
require "active_record/type"

module Vault
  module Latest
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

          attribute_type = _vault_fetch_attribute_type(options)

          # Attribute API
          attribute(attribute_name, attribute_type)

          # Getter
          define_method(attribute_name) do
            unless  __vault_loaded_attributes.include?(attribute_name)
              __vault_load_attribute!(attribute_name, self.class.__vault_attributes[attribute_name])
            end

            read_attribute(attribute_name)
          end

          # Setter
          define_method("#{attribute_name}=") do |value|
            # Prevent the attribute from loading when a value is provided before
            # the attribute is loaded from Vault but only if the model is initialized
            __vault_loaded_attributes << attribute_name

            # Force the update of the attribute, to be consistent with old behaviour
            cast_value = write_attribute(attribute_name, value)

            # Rails 4.2 resets the dirty state if write_attribute is called with the same value after attribute_will_change
            attribute_will_change!(attribute_name)

            cast_value
          end

          serializer = _vault_fetch_serializer(options, attribute_type)

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

        # Encrypt Vault attributes before saving them
        def vault_persist_before_save!
          skip_callback :save, :after, :__vault_persist_attributes!
          before_save :__vault_encrypt_attributes!
        end

        # Define proxy getter and setter methods
        #
        # Override the getter and setter for a particular non-encrypted attribute
        # so that they also call the getter/setter of the encrypted one.
        # This ensures that all the code that uses the attribute in question
        # also updates/retrieves the encrypted value whenever it is available.
        #
        # This method is useful if you have a plaintext attribute that you want to replace with a vault attribute.
        # During a transition period both attributes can be seamlessly read/changed at the same time.
        #
        # @param [String | Symbol] non_encrypted_attribute
        #   The name of original attribute (non-encrypted).
        # @param [String | Symbol] encrypted_attribute
        #   The name of the encrypted attribute.
        #   This makes sure that the encrypted attribute behaves like a real AR attribute.
        # @param [Boolean] (false) encrypted_attribute_only
        #   Whether to read and write to both encrypted and non-encrypted attributes.
        #   Useful for when we stop using the non-encrypted one.
        def vault_attribute_proxy(non_encrypted_attribute, encrypted_attribute, options={})
          if options[:type].present?
            ActiveSupport::Deprecation.warn('The `type` option on `vault_attribute_proxy` is now ignored.  To specify type information you should move the `type` option onto the `vault_attribute` definition.')
          end
          # Only return the encrypted attribute if it's available and encrypted_attribute_only is true.
          define_method(non_encrypted_attribute) do
            return send(encrypted_attribute) if options[:encrypted_attribute_only]

            send(encrypted_attribute) || super()
          end

          # Update only the encrypted attribute if encrypted_attribute_only is true and both attributes otherwise.
          define_method("#{non_encrypted_attribute}=") do |value|
            super(value) unless options[:encrypted_attribute_only]

            send("#{encrypted_attribute}=", value)
          end
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

        def _vault_fetch_attribute_type(options)
          attribute_type = options.fetch(:type, ActiveRecord::Type::Value.new)

          if attribute_type.is_a?(Symbol)
            adapter = ActiveRecord::Base.try(:connection_db_config).try(:adapter) || (ActiveRecord::Base.try(:connection_config) || {})[:adapter]

            if adapter
              ActiveRecord::Type.lookup(attribute_type, adapter: adapter)
            else
              ActiveRecord::Type.lookup(attribute_type) # This call does a db connection, best find a way to configure the adapter
            end
          else
            ActiveModel::Type::Value.new
          end
        rescue ArgumentError => e
          if e.message =~ /Unknown type /
            raise RuntimeError, "Unrecognized attribute type `#{attribute_type}`!"
          else
            raise
          end
        end

        def _vault_fetch_serializer(options, attribute_type)
          if options[:serialize]
            serializer = options[:serialize]

            # Unless a class or module was given, construct our serializer. (Slass
            # is a subset of Module).
            if serializer && !serializer.is_a?(Module)
              Vault::Rails.serializer_for(serializer)
            else
              serializer
            end
          elsif options[:encode] && options[:decode]
            # See if custom encoding or decoding options were given.
            Class.new do
              define_singleton_method(:encode, &options[:encode])
              define_singleton_method(:decode, &options[:decode])
            end
          elsif attribute_type.is_a?(ActiveRecord::Type::Value) && attribute_type.type.present?
            begin
              Vault::Rails.serializer_for(attribute_type.type)
            rescue Vault::Rails::Serializers::UnknownSerializerError
              nil
            end
          end
        end

        def vault_lazy_decrypt?
          !!@vault_lazy_decrypt
        end

        def vault_lazy_decrypt!
          @vault_lazy_decrypt = true
        end

        # works only with convergent encryption
        def vault_persist_all(attribute, records, plaintexts, validate: true)
          options = __vault_attributes[attribute]

          Vault::PerformInBatches.new(attribute, options).encrypt(records, plaintexts, validate: validate)
        end

        # works only with convergent encryption
        # relevant only if lazy decryption is enabled
        def vault_load_all(attribute, records)
          options = __vault_attributes[attribute]

          Vault::PerformInBatches.new(attribute, options).decrypt(records)
        end

        def encrypt_value(attribute, value)
          options = __vault_attributes[attribute]

          key        = options[:key]
          path       = options[:path]
          serializer = options[:serializer]
          convergent = options[:convergent]

          # Apply the serializer to the value, if one exists
          plaintext = serializer ? serializer.encode(value) : value

          Vault::Rails.encrypt(path, key, plaintext, Vault.client, convergent)
        end

        def encrypted_find_by(attributes)
          find_by(search_options(attributes))
        end

        def encrypted_find_by!(attributes)
          find_by!(search_options(attributes))
        end

        def encrypted_where(attributes)
          where(search_options(attributes))
        end

        def encrypted_where_not(attributes)
          where.not(search_options(attributes))
        end

        private

        def search_options(attributes)
          {}.tap do |search_options|
            attributes.each do |attribute_name, attribute_value|
              attribute_options = __vault_attributes[attribute_name]
              encrypted_column = attribute_options[:encrypted_column]

              unless attribute_options[:convergent]
                raise ArgumentError, 'You cannot search with non-convergent fields'
              end

              search_options[encrypted_column] = encrypt_value(attribute_name, attribute_value)
            end
          end
        end
      end

      included do
        # After a resource has been initialized, immediately communicate with
        # Vault and decrypt any attributes unless vault_lazy_decrypt is set.
        after_initialize :__vault_initialize_attributes!

        # After we save the record, persist all the values to Vault and reload
        # them attributes from Vault to ensure we have the proper attributes set.
        # The reason we use `after_save` here is because a `before_save` could
        # run too early in the callback process. If a user is changing Vault
        # attributes in a callback, it is possible that our callback will run
        # before theirs, resulting in attributes that are not persisted.
        after_save :__vault_persist_attributes!

        def __vault_loaded_attributes
          @__vault_loaded_attributes ||= Set.new
        end

        def __vault_initialize_attributes!
          return if self.class.vault_lazy_decrypt?

          __vault_load_attributes!
        end

        # Decrypt all the attributes from Vault.
        def __vault_load_attributes!
          self.class.__vault_attributes.each do |attribute, options|
            self.__vault_load_attribute!(attribute, options)
          end
        end

        # Decrypt and load a single attribute from Vault.
        def __vault_load_attribute!(attribute, options)
          # If the user provided a value for the attribute, do not try to load it from Vault
          return if __vault_loaded_attributes.include?(attribute)

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

          __vault_loaded_attributes << attribute

          # Write the virtual attribute with the plaintext value
          write_attribute(attribute, plaintext).tap { clear_attribute_changes([attribute]) }
        end

        # Encrypt all the attributes using Vault and set the encrypted values back
        # on this model.
        # @return [true]
        def __vault_persist_attributes!
          changes = __vault_encrypt_attributes!(in_after_save: true)

          # If there are any changes to the model, update them all at once,
          # skipping any callbacks and validation. This is okay, because we are
          # already in a transaction due to the callback.
          self.update_columns(changes) unless changes.empty?

          true
        end

        def __vault_encrypt_attributes!(in_after_save: false)
          changes = {}

          self.class.__vault_attributes.each do |attribute, options|
            if c = self.__vault_encrypt_attribute!(attribute, options, in_after_save: in_after_save)
              changes.merge!(c)
            end
          end

          changes
        end

        # Encrypt a single attribute using Vault and persist back onto the
        # encrypted attribute value.
        def __vault_encrypt_attribute!(attribute, options, in_after_save: false)
          # Only persist changed attributes to minimize requests - this helps
          # minimize the number of requests to Vault.

          if in_after_save && ActiveRecord.version >= Gem::Version.new('5.1.0')
            # ActiveRecord 5.2 changes the behaviour of `changed` in `after_*` callbacks
            # https://www.ombulabs.com/blog/rails/upgrades/active-record-5-1-api-changes.html
            # https://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/Dirty.html#method-i-saved_change_to_attribute
            return unless saved_change_to_attribute?(attribute)
          else
            # Rails >= 4.2.8 and < 5.1
            return unless changed.include?("#{attribute}")
          end

          column = options[:encrypted_column]

          # Get the current value of the plaintext attribute
          plaintext = read_attribute(attribute)

          # Generate the ciphertext and store it back as an attribute
          ciphertext = self.class.encrypt_value(attribute, plaintext)

          # Write the attribute back, so that we don't have to reload the record
          # to get the ciphertext
          write_attribute(column, ciphertext)

          # Return the updated column so we can save
          { column => ciphertext }
        end

        def unencrypted_attributes
          encrypted_attributes = self.class.__vault_attributes.values.map {|x| x[:encrypted_column].to_s }
          attributes.delete_if { |attribute| encrypted_attributes.include?(attribute) }
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

            __vault_loaded_attributes.clear

            __vault_initialize_attributes!
            clear_changes_information
          end
        end
      end
    end
  end
end
