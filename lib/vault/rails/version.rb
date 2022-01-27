module Vault
  module Rails
    VERSION = "2.1.1"

    def self.latest?
      ActiveRecord.version >= Gem::Version.new('5.0.0')
    end
  end
end
