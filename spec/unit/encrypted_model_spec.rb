require "spec_helper"

describe Vault::EncryptedModel do
  let(:klass) do
    Class.new do
      include Vault::EncryptedModel

      def self.table_name
        "test"
      end
    end
  end

  describe ".vault_attribute" do
    it "raises an exception if a serializer and :encode is given" do
      expect {
        klass.vault_attribute(:foo, serializer: :json, encode: ->(r) { r })
      }.to raise_error(Vault::Rails::ValidationFailedError)
    end

    it "raises an exception if a serializer and :decode is given" do
      expect {
        klass.vault_attribute(:foo, serializer: :json, decode: ->(r) { r })
      }.to raise_error(Vault::Rails::ValidationFailedError)
    end
  end
end
