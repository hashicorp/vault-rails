module Vault
  module Rails
    class VaultRailsError < RuntimeError; end
    class ValidationFailedError < VaultRailsError; end

    module Serializers
      class UnknownSerializerError < VaultRailsError
        def initialize(key)
          super <<-EOH
  Unknown Vault serializer `:#{key}`. Valid serializers are:

          #{SERIALIZERS.keys.sort.map(&:inspect).join(", ")}

  Please refer to the documentation for more examples.
          EOH
        end
      end
    end
  end
end
