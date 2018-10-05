module Vault
  module Rails
    module Serializers
      module FloatSerializer
        module_function

        def encode(raw)
          return nil if raw.blank?
          raw.to_s
        end

        def decode(raw)
          return nil if raw.blank?
          raw.to_f
        end
      end
    end
  end
end


