module Vault
  module Rails
    module Serializers
      module StringSerializer
        module_function

        def encode(value)
          value.blank? ? value : value.to_s
        end

        def decode(value)
          value
        end
      end
    end
  end
end
