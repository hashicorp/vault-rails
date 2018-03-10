# encoding: utf-8

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
      expect(person.ssn_encrypted.encoding).to eq(Encoding::UTF_8)
    end

    it "decrypts attributes" do
      person = Person.create!(ssn: "123-45-6789")
      person.reload

      expect(person.ssn).to eq("123-45-6789")
      expect(person.ssn.encoding).to eq(Encoding::UTF_8)
    end

    it "tracks dirty attributes" do
      person = Person.create!(ssn: "123-45-6789")

      expect(person.ssn_changed?).to be(false)
      expect(person.ssn_change).to be(nil)
      expect(person.ssn_was).to eq("123-45-6789")

      person.ssn = "111-11-1111"

      expect(person.ssn_changed?).to be(true)
      expect(person.ssn_change).to eq(["123-45-6789", "111-11-1111"])
      expect(person.ssn_was).to eq("123-45-6789")
    end

    it "allows attributes to be unset" do
      person = Person.create!(ssn: "123-45-6789")
      person.update_attributes!(ssn: nil)
      person.reload

      expect(person.ssn).to be(nil)
    end

    it "allows saving without validations" do
      person = Person.new(ssn: "123-456-7890")
      person.save(validate: false)
      expect(person.ssn_encrypted).to match("vault:")
    end

    it "allows attributes to be unset after reload" do
      person = Person.create!(ssn: "123-45-6789")
      person.reload
      person.update_attributes!(ssn: nil)
      person.reload

      expect(person.ssn).to be(nil)
    end

    it "allows attributes to be blank" do
      person = Person.create!(ssn: "123-45-6789")
      person.update_attributes!(ssn: "")
      person.reload

      expect(person.ssn).to eq("")
    end

    it "reloads instance variables on reload" do
      person = Person.create!(ssn: "123-45-6789")
      expect(person.instance_variable_get(:@ssn)).to eq("123-45-6789")

      person.ssn = "111-11-1111"
      person.reload
      expect(person.instance_variable_get(:@ssn)).to eq("123-45-6789")
    end

    it "does not try to encrypt unchanged attributes" do
      person = Person.create!(ssn: "123-45-6789")

      expect(Vault::Rails).to_not receive(:encrypt)
      person.name = "Cinderella"
      person.save!
    end
  end

  context "lazy decrypt" do
    before(:all) do
      Vault::Rails.logical.write("transit/keys/dummy_people_ssn")
    end

    it "encrypts attributes" do
      person = LazyPerson.create!(ssn: "123-45-6789")
      expect(person.ssn_encrypted).to be
      expect(person.ssn_encrypted.encoding).to eq(Encoding::UTF_8)
    end

    it "decrypts attributes" do
      person = LazyPerson.create!(ssn: "123-45-6789")
      person.reload

      expect(person.ssn).to eq("123-45-6789")
      expect(person.ssn.encoding).to eq(Encoding::UTF_8)
    end

    it "does not decrypt on initialization" do
      person = LazyPerson.create!(ssn: "123-45-6789")
      person.reload

      p2 = LazyPerson.find(person.id)

      expect(p2.instance_variable_get("@ssn")).to eq(nil)
      expect(p2.ssn).to eq("123-45-6789")
    end

    it "tracks dirty attributes" do
      person = LazyPerson.create!(ssn: "123-45-6789")

      expect(person.ssn_changed?).to be(false)
      expect(person.ssn_change).to be(nil)
      expect(person.ssn_was).to eq("123-45-6789")

      person.ssn = "111-11-1111"

      expect(person.ssn_changed?).to be(true)
      expect(person.ssn_change).to eq(["123-45-6789", "111-11-1111"])
      expect(person.ssn_was).to eq("123-45-6789")
    end

    it "allows attributes to be unset" do
      person = LazyPerson.create!(ssn: "123-45-6789")
      person.update_attributes!(ssn: nil)
      person.reload

      expect(person.ssn).to be(nil)
    end

    it "allows saving without validations" do
      person = LazyPerson.new(ssn: "123-456-7890")
      expect(person.save(validate: false)).to be(true)
      expect(person.ssn_encrypted).to match("vault:")
    end

    it "allows attributes to be unset after reload" do
      person = LazyPerson.create!(ssn: "123-45-6789")
      person.reload
      person.update_attributes!(ssn: nil)
      person.reload

      expect(person.ssn).to be(nil)
    end

    it "allows attributes to be blank" do
      person = LazyPerson.create!(ssn: "123-45-6789")
      person.update_attributes!(ssn: "")
      person.reload

      expect(person.ssn).to eq("")
    end

    it "reloads instance variables on reload" do
      person = LazyPerson.create!(ssn: "123-45-6789")
      expect(person.instance_variable_get(:@ssn)).to eq("123-45-6789")

      person.ssn = "111-11-1111"
      person.reload

      expect(person.ssn).to eq("123-45-6789")
    end

    it "does not try to encrypt unchanged attributes" do
      person = LazyPerson.create!(ssn: "123-45-6789")

      expect(Vault::Rails).to_not receive(:encrypt)
      person.name = "Cinderella"
      person.save!
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
      expect(person.cc_encrypted.encoding).to eq(Encoding::UTF_8)
    end

    it "decrypts attributes" do
      person = Person.create!(credit_card: "1234567890111213")
      person.reload

      expect(person.credit_card).to eq("1234567890111213")
      expect(person.credit_card.encoding).to eq(Encoding::UTF_8)
    end

    it "tracks dirty attributes" do
      person = Person.create!(credit_card: "1234567890111213")

      expect(person.credit_card_changed?).to be(false)
      expect(person.credit_card_change).to eq(nil)
      expect(person.credit_card_was).to eq("1234567890111213")

      person.credit_card = "123456789010"

      expect(person.credit_card_changed?).to be(true)
      expect(person.credit_card_change).to eq(["1234567890111213", "123456789010"])
      expect(person.credit_card_was).to eq("1234567890111213")
    end

    it "allows attributes to be unset" do
      person = Person.create!(credit_card: "1234567890111213")
      person.update_attributes!(credit_card: nil)
      person.reload

      expect(person.credit_card).to be(nil)
    end

    it "allows attributes to be blank" do
      person = Person.create!(credit_card: "1234567890111213")
      person.update_attributes!(credit_card: "")
      person.reload

      expect(person.credit_card).to eq("")
    end
  end

  context "with non-ASCII characters" do
    before(:all) do
      Vault::Rails.sys.mount("non-ascii", :transit)
      Vault::Rails.logical.write("non-ascii/keys/people_non_ascii")
    end

    it "encrypts attributes" do
      person = Person.create!(non_ascii: "dás ümlaut")
      expect(person.non_ascii_encrypted).to be
      expect(person.non_ascii_encrypted.encoding).to eq(Encoding::UTF_8)
    end

    it "decrypts attributes" do
      person = Person.create!(non_ascii: "dás ümlaut")
      person.reload

      expect(person.non_ascii).to eq("dás ümlaut")
      expect(person.non_ascii.encoding).to eq(Encoding::UTF_8)
    end

    it "tracks dirty attributes" do
      person = Person.create!(non_ascii: "dás ümlaut")

      expect(person.non_ascii_changed?).to be(false)
      expect(person.non_ascii_change).to eq(nil)
      expect(person.non_ascii_was).to eq("dás ümlaut")

      person.non_ascii = "él ñiñô"

      expect(person.non_ascii_changed?).to be(true)
      expect(person.non_ascii_change).to eq(["dás ümlaut", "él ñiñô"])
      expect(person.non_ascii_was).to eq("dás ümlaut")
    end

    it "allows attributes to be unset" do
      person = Person.create!(non_ascii: "dás ümlaut")
      person.update_attributes!(non_ascii: nil)
      person.reload

      expect(person.non_ascii).to be(nil)
    end

    it "allows attributes to be blank" do
      person = Person.create!(non_ascii: "dás ümlaut")
      person.update_attributes!(non_ascii: "")
      person.reload

      expect(person.non_ascii).to eq("")
    end
  end

  context "with the :json serializer"  do
    before(:all) do
      Vault::Rails.logical.write("transit/keys/dummy_people_details")
    end

    it "has a default value for unpersisted records" do
      person = Person.new
      expect(person.details).to eq({})
    end

    it "has a default value for persisted records" do
      person = Person.create!
      expect(person.details).to eq({})
    end

    it "tracks dirty attributes" do
      person = Person.create!(details: { "foo" => "bar" })

      expect(person.details_changed?).to be(false)
      expect(person.details_change).to be(nil)
      expect(person.details_was).to eq({ "foo" => "bar" })

      person.details = { "zip" => "zap" }

      expect(person.details_changed?).to be(true)
      expect(person.details_change).to eq([{ "foo" => "bar" }, { "zip" => "zap" }])
      expect(person.details_was).to eq({ "foo" => "bar" })
    end

    it "encodes and decodes attributes" do
      person = Person.create!(details: { "foo" => "bar", "zip" => 1 })
      person.reload

      raw = Vault::Rails.decrypt("transit", "dummy_people_details", person.details_encrypted)
      expect(raw).to eq("{\"foo\":\"bar\",\"zip\":1}")

      expect(person.details).to eq("foo" => "bar", "zip" => 1)
    end
  end

  context "with a custom serializer" do
    before(:all) do
      Vault::Rails.logical.write("transit/keys/dummy_people_business_card")
    end

    it "encodes and decodes attributes" do
      person = Person.create!(business_card: "data")
      person.reload

      raw = Vault::Rails.decrypt("transit", "dummy_people_business_card", person.business_card_encrypted)
      expect(raw).to eq("01100100011000010111010001100001")

      expect(person.business_card).to eq("data")
    end
  end

  context "with custom encode/decode proc" do
    before(:all) do
      Vault::Rails.logical.write("transit/keys/dummy_people_favorite_color")
    end

    it "encodes and decodes attributes" do
      person = Person.create!(favorite_color: "blue")
      person.reload

      raw = Vault::Rails.decrypt("transit", "dummy_people_favorite_color", person.favorite_color_encrypted)
      expect(raw).to eq("xxxbluexxx")

      expect(person.favorite_color).to eq("blue")
    end
  end

  context "with convergent encryption enabled" do
    before(:all) do
      Vault::Rails.logical.write(
        "transit/keys/dummy_people_first_pet",
        convergent_encryption: true,
        derived: true
      )
    end

    it "always generates the same ciphertext given the same plaintext" do
      first_person = Person.create!(first_pet: "Rover")
      second_person = Person.create!(first_pet: "Rover")

      first_person.reload
      second_person.reload

      expect(first_person.first_pet_encrypted).to eq(second_person.first_pet_encrypted)
    end

    it "only generates the same ciphertext given the same plaintext" do
      first_person = Person.create!(first_pet: "Fido")
      second_person = Person.create!(first_pet: "Spot")

      first_person.reload
      second_person.reload

      expect(first_person.first_pet_encrypted).not_to eq(second_person.first_pet_encrypted)
    end
  end

  context 'with errors' do
    it 'raises the appropriate exception' do
      expect {
        Vault::Rails.encrypt('/bogus/path', 'bogus', 'bogus')
      }.to raise_error(Vault::HTTPClientError)
    end
  end

  context "in-memory encryption" do
    before(:each) do
      # force in-memory encryption
      allow(Vault::Rails).to receive(:enabled?).and_return(false)
    end

    context "without convergent encryption enabled" do
      it "encrypts attributes" do
        person = Person.create!(ssn: "123-45-6789")
        expect(person.ssn_encrypted).to be
        expect(person.ssn_encrypted.encoding).to eq(Encoding::UTF_8)
      end

      it "decrypts attributes" do
        person = Person.create!(ssn: "123-45-6789")
        person.reload

        expect(person.ssn).to eq("123-45-6789")
        expect(person.ssn.encoding).to eq(Encoding::UTF_8)
      end
    end

    context "with convergent encryption enabled" do
      before(:all) do
        Vault::Rails.logical.write(
          "transit/keys/dummy_people_first_pet",
          convergent_encryption: true,
          derived: true
        )
      end

      it "always generates the same ciphertext given the same plaintext" do
        first_person = Person.create!(first_pet: "Rover")
        second_person = Person.create!(first_pet: "Rover")

        first_person.reload
        second_person.reload

        expect(first_person.first_pet_encrypted).to eq(second_person.first_pet_encrypted)
      end

      it "only generates the same ciphertext given the same plaintext" do
        first_person = Person.create!(first_pet: "Fido")
        second_person = Person.create!(first_pet: "Spot")

        first_person.reload
        second_person.reload

        expect(first_person.first_pet_encrypted).not_to eq(second_person.first_pet_encrypted)
      end
    end
  end
end
