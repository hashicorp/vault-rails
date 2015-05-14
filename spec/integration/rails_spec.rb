require "spec_helper"

describe Vault::Rails do
  context "with default options" do
    before(:all) do
      Vault.sys.mount("transit", :transit)
      Vault.logical.write("transit/keys/dummy_people_ssn")
    end

    it "encrypts attributes" do
      person = Person.create!(ssn: "123-45-6789")
      expect(person.ssn_encrypted).to be
    end

    it "decrypts attributes" do
      person = Person.create!(ssn: "123-45-6789")
      person = Person.find(person.id)

      expect(person.ssn).to eq("123-45-6789")
    end
  end

  context "with custom options" do
    before(:all) do
      Vault.sys.mount("credit-secrets", :transit)
      Vault.logical.write("credit-secrets/keys/people_credit_cards")
    end

    it "encrypts attributes" do
      person = Person.create!(credit_card: "1234567890111213")
      expect(person.cc_encrypted).to be
    end

    it "decrypts attributes" do
      person = Person.create!(credit_card: "1234567890111213")
      person = Person.find(person.id)

      expect(person.credit_card).to eq("1234567890111213")
    end
  end
end
