require "vault"

require "base64"
require "json"

module Vault
  class << self
    # The name of this application.
    #
    # @return [String]
    attr_writer :application

    # The name of the application. This must be set or an error will be
    # returned.
    #
    # @return [String]
    def application
      if !defined?(@application) || @application.nil?
        raise RuntimeError, "Must set `Vault.application'!"
      end

      return @application
    end
  end

  autoload :EncryptedModel, "vault/encrypted_model"

  module Rails
  end
end
