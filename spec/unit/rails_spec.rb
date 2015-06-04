require "spec_helper"

describe Vault::Rails do
  describe ".application" do
    it "returns the application" do
      Vault::Rails.instance_variable_set(:@application, "dummy")
      expect(Vault::Rails.application).to eq("dummy")
    end

    it "raises an error if unset" do
      Vault::Rails.instance_variable_set(:@application, nil)
      expect { Vault::Rails.application }.to raise_error
    end
  end

  describe ".application=" do
    before do
      @_value = Vault::Rails.instance_variable_get(:@application)
    end

    after do
      Vault::Rails.instance_variable_set(:@application, @_value)
    end

    it "sets the value" do
      Vault::Rails.application = "dummy"
      expect(Vault::Rails.instance_variable_get(:@application)).to eq("dummy")
    end
  end

  describe ".enabled?" do
    before do
      @_value = Vault::Rails.instance_variable_get(:@enabled)
    end

    after do
      Vault::Rails.instance_variable_set(:@enabled, @_value)
    end

    it "defaults to false" do
      Vault::Rails.instance_variable_set(:@enabled, nil)
      expect(Vault::Rails.enabled?).to be(false)
    end

    it "returns the value if set" do
      Vault::Rails.enabled = true
      expect(Vault::Rails.enabled?).to be(true)

      Vault::Rails.enabled = false
      expect(Vault::Rails.enabled?).to be(false)
    end
  end

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
