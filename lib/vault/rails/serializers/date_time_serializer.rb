module Vault
  module Rails
    module Serializers
      # Converts datetime objects to and from ISO 8601 format with 3
      # fractional seconds
      module DateTimeSerializer
        include TimeSerializer
        module_function :encode, :decode

        def decode(raw)
          time = super
          time.present? ? time.to_datetime : time
        end
      end
    end
  end
end
