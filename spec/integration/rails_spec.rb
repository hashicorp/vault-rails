require "spec_helper"

describe Vault::Rails do
  before(:all) do
    Vault::Rails.sys.mount("transit", :transit)
  end

  context "with default options" do
    before(:all) do
      Vault::Rails.logical.write("transit/keys/dummy_people_ssn")
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

    it "allows attributes to be unset" do
      person = Person.create!(ssn: "123-45-6789")
      person.update_attributes!(ssn: nil)

      person = Person.find(person.id)
      expect(person.ssn).to be(nil)
    end
  end

  context "with custom options" do
    before(:all) do
      Vault::Rails.sys.mount("credit-secrets", :transit)
      Vault::Rails.logical.write("credit-secrets/keys/people_credit_cards")
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

    it "allows attributes to be unset" do
      person = Person.create!(credit_card: "1234567890111213")
      person.update_attributes!(credit_card: nil)

      person = Person.find(person.id)
      expect(person.credit_card).to be(nil)
    end
  end
end
