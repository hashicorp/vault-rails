# encoding: utf-8

require "spec_helper"

describe Vault::Rails do
  before(:each) do
    Person.delete_all
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

    it 'does not pollute changes / dirty attributes / when loading a record from the db' do
      Person.create!(ssn: "123-45-6789")

      expect(Person.last.changes).to be_blank
    end

    it "allows attributes to be updated with nil values" do
      person = Person.create!(ssn: "123-45-6789")
      person.update!(ssn: nil)
      person.reload

      expect(person.ssn).to be(nil)
    end

    it "allows attributes to be unset" do
      person = Person.create!(ssn: "123-45-6789")
      person.ssn = nil
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
      person.update!(ssn: nil)
      person.reload

      expect(person.ssn).to be(nil)
    end

    it "allows attributes to be blank" do
      person = Person.create!(ssn: "123-45-6789")
      person.update!(ssn: "")
      person.reload

      expect(person.ssn).to eq("")
    end

    it "loads attributes on initialize" do
      person = Person.create!(ssn: '123-45-6789', non_ascii: 'some text')

      expect_any_instance_of(Person).to receive(:__vault_load_attributes!).once.and_call_original
      Person.__vault_attributes.keys.each do |attr|
        expect_any_instance_of(Person).to receive(:__vault_load_attribute!).with(attr, any_args).once
      end

      Person.find(person.id)
    end

    it "reloads attributes on reload" do
      person = Person.create!(ssn: "123-45-6789")
      expect(person.ssn).to eq("123-45-6789")

      person.ssn = "111-11-1111"

      expect(person).to receive(:__vault_load_attributes!).once.and_call_original
      Person.__vault_attributes.keys.each do |attr|
        expect(person).to receive(:__vault_load_attribute!).with(attr, any_args).once.and_call_original
      end

      person.reload

      expect(person.ssn).to eq("123-45-6789")
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
      lazy_person = LazyPerson.create!(ssn: "123-45-6789")

      expect_any_instance_of(LazyPerson).not_to receive(:__vault_load_attribute!)

      LazyPerson.find(lazy_person.id)
    end

    it 'only decrypts attributes that are used' do
      person = LazyPerson.create!(ssn: "123-45-6789", non_ascii: 'some text')

      found_person = LazyPerson.find(person.id)
      expect(found_person).to receive(:__vault_load_attribute!).with(:ssn, any_args).once

      found_person.ssn
    end

    it 'does not decrypt attributes on reload' do
      person = LazyPerson.create!(ssn: "123-45-6789", non_ascii: 'some text')
      expect(person.ssn).not_to be_nil

      if Vault::Rails.latest?
        expect(person).not_to receive(:__vault_load_attributes!)
      end

      person.reload
      expect(person.read_attribute(:ssn)).to be nil
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

    it 'does not pollute changes / dirty attributes / when loading a record from the db' do
      Person.create!(ssn: "123-45-6789")

      person = Person.last
      expect(person.changes).to be_blank
      expect(person.ssn).to eq('123-45-6789')
      expect(person.changes).to be_blank
    end

    it "allows attributes to be unset" do
      person = LazyPerson.create!(ssn: "123-45-6789")
      person.update!(ssn: nil)
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
      person.update!(ssn: nil)
      person.reload

      expect(person.ssn).to be(nil)
    end

    it "allows attributes to be unset" do
      person = LazyPerson.create!(ssn: "123-45-6789")
      person.ssn = nil
      expect(person.ssn).to be(nil)
    end

    it "allows attributes to be blank" do
      person = LazyPerson.create!(ssn: "123-45-6789")
      person.update!(ssn: "")
      person.reload

      expect(person.ssn).to eq("")
    end

    it "resets attributes on reload" do
      person = LazyPerson.create!(ssn: "123-45-6789")
      expect(person.ssn).to eq("123-45-6789")

      person.ssn = "111-11-1111"

      if Vault::Rails.latest?
        expect(person).to receive(:__vault_initialize_attributes!).once.and_call_original
      end
      expect(person).to receive(:__vault_load_attribute!).once.with(:ssn, any_args).and_call_original

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
      person.update!(credit_card: nil)
      person.reload

      expect(person.credit_card).to be(nil)
    end

    it "allows attributes to be blank" do
      person = Person.create!(credit_card: "1234567890111213")
      person.update!(credit_card: "")
      person.reload

      expect(person.credit_card).to eq("")
    end
  end

  context "with non-ASCII characters" do
    before(:all) do
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
      person.update!(non_ascii: nil)
      person.reload

      expect(person.non_ascii).to be(nil)
    end

    it "allows attributes to be blank" do
      person = Person.create!(non_ascii: "dás ümlaut")
      person.update!(non_ascii: "")
      person.reload

      expect(person.non_ascii).to eq("")
    end
  end

  context "with the :json serializer"  do
    before(:all) do
      Vault::Rails.logical.write("transit/keys/dummy_people_details")
    end

    it "allows nil for unpersisted records" do
      person = Person.new
      expect(person.details).to be_nil
    end

    it "allows nil for persisted records" do
      person = Person.create!
      expect(person.details).to be_nil
    end

    it 'saves an empty hash' do
      person = Person.create!(details: {})
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

  context 'when convergent encryption is used' do
    before :each do
      allow(Vault::Rails).to receive(:convergent_encryption_context).and_return('a' * 16).at_least(:once)
    end

    it 'generates the same ciphertext for the same plaintext' do
      email = 'user@example.com'

      first_person = Person.create!(email: email)
      second_person = Person.create!(email: email)

      first_person.reload
      second_person.reload

      expect(first_person.email_encrypted).not_to be_blank
      expect(second_person.email_encrypted).not_to be_blank

      expect(first_person.email_encrypted).to eq second_person.email_encrypted
    end

    it 'generates different ciphertexts for different plaintexts' do
      first_person  = Person.create!(email: 'john@example.com')
      second_person = Person.create!(email: 'todd@example.com')

      first_person.reload
      second_person.reload

      expect(first_person.email_encrypted).not_to eq(second_person.email_encrypted)
    end
  end

  context 'when called with type other than string' do
    it 'casts the value to the correct type' do
      person = Person.new
      date_string = '2000-10-10'
      date = Date.parse(date_string)

      person.date_of_birth_plaintext = date_string

      expect(person.date_of_birth_plaintext).to eq date
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
      # Force in-memory encryption
      allow(Vault::Rails).to receive(:enabled?).and_return(false)
    end

    context 'when convergent encryption is not used' do
      it 'generates different ciphertexts for the same plaintext' do
        ssn = '123-45-6789'

        first_person = Person.create!(ssn: ssn)
        second_person = Person.create!(ssn: ssn)

        first_person.reload
        second_person.reload

        expect(first_person.ssn).to eq ssn
        expect(second_person.ssn).to eq ssn

        expect(first_person.ssn_encrypted).not_to eq(second_person.ssn_encrypted)
      end
    end

    context 'when convergent encryption is used' do
      before :each do
        allow(Vault::Rails).to receive(:convergent_encryption_context).and_return('a' * 16).at_least(:once)
      end

      it 'generates the same ciphertext when given the same plaintext' do
        email = 'knifemaker@example.com'

        first_person = Person.create!(email: email)
        second_person = Person.create!(email: email)

        first_person.reload
        second_person.reload

        expect(first_person.email_encrypted).not_to be_blank
        expect(second_person.email_encrypted).not_to be_blank

        expect(first_person.email_encrypted).to eq(second_person.email_encrypted)
      end

      it "generates different ciphertext for different plaintext" do
        first_person = Person.create!(email: "medford@example.com")
        second_person = Person.create!(email: "begg@example.com")

        first_person.reload
        second_person.reload

        expect(first_person.email_encrypted).not_to eq(second_person.email_encrypted)
      end
    end

    context '.vault_load_all' do
      it 'works with records with nil and blank values' do
        first_person = LazyPerson.create!(passport_number: nil)
        second_person = LazyPerson.create!(passport_number: '')

        first_person.reload
        second_person.reload

        LazyPerson.vault_load_all(:passport_number, [first_person, second_person])
        expect(first_person.passport_number).to eq(nil)
        expect(second_person.passport_number).to eq('')
      end
    end
  end

  context 'uniqueness validation' do
    before do
      allow(Vault::Rails).to receive(:convergent_encryption_context).and_return('a' * 16).at_least(:once)
    end

    context 'new record with duplicated driving licence number' do
      it 'is invalid' do
        Person.create!(driving_licence_number: '12345678')
        same_driving_licence_number_person = Person.new(driving_licence_number: '12345678')

        expect(same_driving_licence_number_person).not_to be_valid
        expect(same_driving_licence_number_person.errors[:driving_licence_number]).to include('has already been taken')
        expect(same_driving_licence_number_person.errors[:driving_licence_number_encrypted]).not_to include('has already been taken')
      end
    end

    context 'new record with new different licence number' do
      it 'is valid' do
        Person.create!(driving_licence_number: '12345678')
        different_driving_licence_number_person = Person.new(driving_licence_number: '12345679')

        expect(different_driving_licence_number_person).to be_valid
      end
    end

    context 'old record with duplicated driving licence number' do
      it 'is invalid' do
        Person.create!(driving_licence_number: '12345678')
        another_person = Person.create!(driving_licence_number: '12345679')
        another_person.driving_licence_number = '12345678'

        expect(another_person).not_to be_valid
      end
    end

    context 'attribute with defined serializer' do
      context 'new record with duplicated IP address' do
        it 'is invalid' do
          Person.create!(ip_address: IPAddr.new('127.0.0.1'))
          same_ip_address_person = Person.new(ip_address: IPAddr.new('127.0.0.1'))

          expect(same_ip_address_person).not_to be_valid
        end
      end

      context 'new record with different IP address' do
        it 'is valid' do
          Person.create!(ip_address: IPAddr.new('127.0.0.1'))
          different_ip_address_person = Person.new(ip_address: IPAddr.new('192.168.0.1'))

          expect(different_ip_address_person).to be_valid
        end
      end

      context 'old record with duplicated IP address' do
        it 'is invalid' do
          Person.create!(ip_address: IPAddr.new('127.0.0.1'))
          another_person = Person.create!(ip_address: IPAddr.new('192.168.0.1'))
          another_person.ip_address = IPAddr.new('127.0.0.1')

          expect(another_person).not_to be_valid
        end
      end
    end
  end

  context 'batch encryption and decryption' do
    before do
      allow(Vault::Rails).to receive(:convergent_encryption_context).and_return('a' * 16).at_least(:once)
    end

    describe '.vault_load_all' do
      it 'calls Vault just once' do
        first_person = LazyPerson.create!(passport_number: '12345678')
        second_person = LazyPerson.create!(passport_number: '12345679')

        people = [first_person.reload, second_person.reload]
        expect(Vault.logical).to receive(:write).once.and_call_original
        LazyPerson.vault_load_all(:passport_number, people)

        first_person.passport_number
        second_person.passport_number
      end

      it 'loads the attribute of all records' do
        first_person = LazyPerson.create!(passport_number: '12345678')
        second_person = LazyPerson.create!(passport_number: '12345679')

        first_person.reload
        second_person.reload

        LazyPerson.vault_load_all(:passport_number, [first_person, second_person])
        expect(first_person.passport_number).to eq('12345678')
        expect(second_person.passport_number).to eq('12345679')
      end
    end

    describe '.vault_persist_all' do
      it 'calls Vault just once' do
        first_person = LazyPerson.new
        second_person = LazyPerson.new

        expect(Vault.logical).to receive(:write).once.and_call_original
        LazyPerson.vault_persist_all(:passport_number, [first_person, second_person], %w(12345678 12345679))
      end

      it 'saves the attribute of all records' do
        first_person = LazyPerson.new
        second_person = LazyPerson.new

        LazyPerson.vault_persist_all(:passport_number, [first_person, second_person], %w(12345678 12345679))

        expect(first_person.reload.passport_number).to eq('12345678')
        expect(second_person.reload.passport_number).to eq('12345679')
      end

      context 'skipped validations' do
        it 'saves even invalid records' do
          first_person = LazyPerson.new
          allow(first_person).to receive(:valid?).and_return(false)

          LazyPerson.vault_persist_all(:passport_number, [first_person], %w(12345678), validate: false)

          expect(first_person.reload.passport_number).to eq('12345678')
        end
      end
    end
  end

  describe '.encrypted_find_by' do
    before do
      allow(Vault::Rails).to receive(:convergent_encryption_context).and_return('a' * 16).at_least(:once)
    end

    it 'finds the expected record' do
      first_person = LazyPerson.create!(passport_number: '12345678')
      LazyPerson.create!(passport_number: '12345678')
      LazyPerson.create!(passport_number: '87654321')

      expect(LazyPerson.encrypted_find_by(passport_number: '12345678')).to eq(first_person)
    end

    context 'searching by attributes with defined serializer' do
      it 'finds the expected record' do
        first_person = Person.create!(ip_address: IPAddr.new('127.0.0.1'))
        Person.create!(ip_address: IPAddr.new('192.168.0.1'))

        expect(Person.encrypted_find_by(ip_address: IPAddr.new('127.0.0.1'))).to eq(first_person)
      end
    end

    context 'searching by multiple attributes' do
      it 'finds the expected record' do
        first_person = Person.create!(ip_address: IPAddr.new('127.0.0.1'), driving_licence_number: '12345678')

        expect(Person.encrypted_find_by(ip_address: IPAddr.new('127.0.0.1'), driving_licence_number: '12345678')).to eq(first_person)
      end
    end

    context 'non-convergently encrypted attributes' do
      it 'raises an exception' do
        expect { LazyPerson.encrypted_find_by(ssn: '12345678') }.to raise_error('You cannot search with non-convergent fields')
      end
    end
  end

  describe '.encrypted_find_by!' do
    before do
      allow(Vault::Rails).to receive(:convergent_encryption_context).and_return('a' * 16).at_least(:once)
    end

    it 'finds the expected record' do
      first_person = LazyPerson.create!(passport_number: '12345678')
      LazyPerson.create!(passport_number: '12345678')
      LazyPerson.create!(passport_number: '87654321')

      expect(LazyPerson.encrypted_find_by!(passport_number: '12345678')).to eq(first_person)
    end

    context 'searching by attributes with defined serializer' do
      it 'finds the expected record' do
        first_person = Person.create!(ip_address: IPAddr.new('127.0.0.1'))
        Person.create!(ip_address: IPAddr.new('192.168.0.1'))

        expect(Person.encrypted_find_by!(ip_address: IPAddr.new('127.0.0.1'))).to eq(first_person)
      end
    end

    context 'searching by multiple attributes' do
      it 'finds the expected record' do
        first_person = Person.create!(ip_address: IPAddr.new('127.0.0.1'), driving_licence_number: '12345678')

        expect(Person.encrypted_find_by!(ip_address: IPAddr.new('127.0.0.1'), driving_licence_number: '12345678')).to eq(first_person)
      end
    end

    context 'searching missing record' do
      it 'raises an exception' do
        expect { LazyPerson.encrypted_find_by!(passport_number: '000') }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context 'non-convergently encrypted attributes' do
      it 'raises an exception' do
        expect { LazyPerson.encrypted_find_by!(ssn: '12345678') }.to raise_error('You cannot search with non-convergent fields')
      end
    end
  end

  describe '.encrypted_where' do
    before do
      allow(Vault::Rails).to receive(:convergent_encryption_context).and_return('a' * 16).at_least(:once)
    end

    it 'finds the expected records' do
      first_person = LazyPerson.create!(passport_number: '12345678')
      second_person = LazyPerson.create!(passport_number: '12345678')
      LazyPerson.create!(passport_number: '87654321')

      expect(LazyPerson.encrypted_where(passport_number: '12345678').pluck(:id)).to match_array([first_person, second_person].map(&:id))
    end

    context 'searching by attributes with defined serializer' do
      it 'finds the expected records' do
        first_person = Person.create!(ip_address: IPAddr.new('127.0.0.1'))
        Person.create!(ip_address: IPAddr.new('192.168.0.1'))

        expect(Person.encrypted_where(ip_address: IPAddr.new('127.0.0.1')).pluck(:id)).to match_array([first_person.id])
      end
    end

    context 'searching by multiple attributes' do
      it 'finds the expected records' do
        first_person = Person.create!(ip_address: IPAddr.new('127.0.0.1'), driving_licence_number: '12345678')

        expect(Person.encrypted_where(ip_address: IPAddr.new('127.0.0.1'), driving_licence_number: '12345678').pluck(:id)).to match_array([first_person.id])
      end
    end

    context 'non-convergently encrypted attributes' do
      it 'raises an exception' do
        expect { LazyPerson.encrypted_where(ssn: '12345678') }.to raise_error('You cannot search with non-convergent fields')
      end
    end
  end

  describe '.encrypted_where_not' do
    before do
      allow(Vault::Rails).to receive(:convergent_encryption_context).and_return('a' * 16).at_least(:once)
    end

    it 'finds the expected records' do
      first_person = LazyPerson.create!(passport_number: '12345678')
      second_person = LazyPerson.create!(passport_number: '12345678')
      third_person = LazyPerson.create!(passport_number: '87654321')

      expect(LazyPerson.encrypted_where_not(passport_number: nil).pluck(:id)).to match_array([first_person, second_person, third_person].map(&:id))
    end
  end
end
