module Vault
  module Rails
    class VaultRailsError < RuntimeError; end

    class UnknownSerializerError < VaultRailsError
      def initialize(key)
        super <<-EOH
  Unknown Vault serializer `:#{key}'. Valid serializers are:

      #{SERIALIZERS.keys.sort.map(&:inspect).join(", ")}

  Please refer to the documentation for more examples.
  EOH
      end
    end

    class ValidationFailedError < VaultRailsError; end
  end
end
