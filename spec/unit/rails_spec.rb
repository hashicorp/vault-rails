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
    it "sets the value" do
      Vault::Rails.application = "dummy"
      expect(Vault::Rails.instance_variable_get(:@application)).to eq("dummy")
    end
  end

  describe ".enabled?" do
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
end
