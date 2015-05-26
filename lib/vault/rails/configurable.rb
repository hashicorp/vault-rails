module Vault
  module Rails
    module Configurable
      include Vault::Configurable

      # The name of the Vault::Rails application.
      #
      # @raise [RuntimeError]
      #   if the application has not been set
      #
      # @return [String]
      def application
        if !defined?(@application) || @application.nil?
          raise RuntimeError, "Must set `Vault::Rails#application'!"
        end
        return @application
      end

      # Set the name of the application.
      #
      # @param [String] val
      def application=(val)
        @application = val
      end

      # Whether the connection to Vault is enabled. The default value is `false`,
      # which means vault-rails will perform in-memory encryption/decryption and
      # not attempt to talk to a reail Vault server. This is useful for
      # development and testing.
      #
      # @return [true, false]
      def enabled?
        if !defined?(@enabled) || @enabled.nil?
          return false
        end
        return @enabled
      end

      # Sets whether Vault is enabled. Users can set this in an initializer
      # depending on their Rails environment.
      #
      # @example
      #   Vault.configure do |vault|
      #     vault.enabled = Rails.env.production?
      #   end
      #
      # @return [true, false]
      def enabled=(val)
        @enabled = !!val
      end
    end
  end
end
