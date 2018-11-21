require "active_support/concern"
require "active_support/deprecation"

module Vault
  module AttributeProxy
    extend ActiveSupport::Concern

    included do
      ActiveSupport::Deprecation.warn('Vault::AttributeProxy is no longer required, `vault_attribute_proxy` comes via `Vault::EncryptedModel` so you can remove `include Vault::AttributeProxy` from your model.')
    end
  end
end
