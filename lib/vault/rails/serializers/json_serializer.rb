require "json"

module Vault
  module Rails
    module Serializers
      module JSONSerializer
        DECODE_OPTIONS = {
          max_nested:       false,
          create_additions: false,
        }.freeze

        def self.encode(raw)
          return if raw.nil?
          return raw if raw.is_a?(String)
          JSON.fast_generate(raw)
        end


        def self.decode(raw)
          return if raw.nil?
          JSON.parse(raw, DECODE_OPTIONS)
        end
      end
    end
  end
end
