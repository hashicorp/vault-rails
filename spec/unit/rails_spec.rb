require "spec_helper"

describe Vault do
  describe ".application" do
    it "returns the application" do
      Vault.instance_variable_set(:@application, "test")
      expect(Vault.application).to eq("test")
    end

    it "raises an error if unset" do
      Vault.instance_variable_set(:@application, nil)
      expect { Vault.application }.to raise_error
    end
  end

  describe ".application=" do
    it "sets the value" do
      Vault.application = "test"
      expect(Vault.instance_variable_get(:@application)).to eq("test")
    end
  end

  describe "Rails" do
    it "is defined" do
      expect { Vault.const_get(:Rails) }.to_not raise_error
    end
  end
end
