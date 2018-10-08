module Vault
  module Rails
    module Serializers
      module IntegerSerializer
        module_function

        def encode(raw)
          return nil if raw.blank?
          raw.to_s
        end

        def decode(raw)
          return nil if raw.blank?
          raw.to_i
        end
      end
    end
  end
end
