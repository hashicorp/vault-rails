module Vault
  module Rails
    VERSION = "2.0.5"

    def self.latest?
      ActiveRecord.version >= Gem::Version.new('5.0.0')
    end
  end
end
