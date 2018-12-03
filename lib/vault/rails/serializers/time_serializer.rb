module Vault
  module Rails
    module Serializers
      # Converts time objects to and from ISO 8601 format with 3
      # fractional seconds
      module TimeSerializer
        module_function

        def encode(raw)
          return nil if raw.blank?

          raw = Time.parse(raw) if raw.is_a? String
          raw.iso8601(3)
        end

        def decode(raw)
          return nil if raw.blank?
          Time.iso8601(raw)
        end
      end
    end
  end
end
