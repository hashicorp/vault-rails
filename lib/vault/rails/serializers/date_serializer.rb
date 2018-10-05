module Vault
  module Rails
    module Serializers
      # Converts date objects to and from ISO 8601 format (%F)
      module DateSerializer
        module_function

        def encode(raw)
          return nil if raw.blank?

          raw = Date.parse(raw) if raw.is_a? String
          raw.strftime('%F')
        end

        def decode(raw)
          return nil if raw.blank?
          Date.strptime(raw, '%F')
        end
      end
    end
  end
end
