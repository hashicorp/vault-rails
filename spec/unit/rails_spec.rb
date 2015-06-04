require "spec_helper"

describe Vault::Rails do
  describe ".serializer_for" do
    it "accepts a string" do
      serializer = Vault::Rails.serializer_for("json")
      expect(serializer).to be(Vault::Rails::JSONSerializer)
    end

    it "accepts a symbol" do
      serializer = Vault::Rails.serializer_for(:json)
      expect(serializer).to be(Vault::Rails::JSONSerializer)
    end

    it "raises an exception when there is no serializer for the key" do
      expect {
        Vault::Rails.serializer_for(:not_a_serializer)
      }.to raise_error(Vault::Rails::UnknownSerializerError) { |e|
        expect(e.message).to match("Unknown Vault serializer `:not_a_serializer'")
      }
    end
  end
end
