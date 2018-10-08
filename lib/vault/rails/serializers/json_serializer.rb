module Vault
  module Rails
    module Serializers
      module JSONSerializer
        DECODE_OPTIONS = {
          max_nested:       false,
          create_additions: false,
        }.freeze

        def self.encode(raw)
          self._init!

          raw = {} if raw.nil?

          JSON.fast_generate(raw)
        end

        def self.decode(raw)
          self._init!

          return {} if raw.nil? || raw.empty?
          JSON.parse(raw, DECODE_OPTIONS)
        end

        protected

        def self._init!
          return if defined?(@_init)
          require "json"
          @_init = true
        end
      end
    end
  end
end
