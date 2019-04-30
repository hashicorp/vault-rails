require "spec_helper"

describe Vault::EncryptedModel do
  describe ".vault_attribute" do
    let(:person) { Person.new }

    it "raises an exception if a serializer and :encode is given" do
      expect {
        Person.vault_attribute(:foo, serializer: :json, encode: ->(r) { r })
      }.to raise_error(Vault::Rails::ValidationFailedError)
    end

    it "raises an exception if a serializer and :decode is given" do
      expect {
        Person.vault_attribute(:foo, serializer: :json, decode: ->(r) { r })
      }.to raise_error(Vault::Rails::ValidationFailedError)
    end

    it "defines a getter" do
      expect(person).to respond_to(:ssn)
    end

    it "defines a setter" do
      expect(person).to respond_to(:ssn=)
    end

    it "defines a checker" do
      expect(person).to respond_to(:ssn?)
    end

    it "defines dirty attribute methods" do
      expect(person).to respond_to(:ssn_change)
      expect(person).to respond_to(:ssn_changed?)
      expect(person).to respond_to(:ssn_was)
    end

    context 'with custom attribute types' do
      it 'defines an integer attribute' do
        Vault::Rails.logical.write("transit/keys/dummy_people_integer_data")

        person = Person.new
        person.integer_data = '1'

        expect(person.integer_data).to eq 1

        person.save
        person.reload

        expect(person.integer_data).to eq 1
      end

      it 'defines a float attribute' do
        Vault::Rails.logical.write("transit/keys/dummy_people_float_data")

        person = Person.new
        person.float_data = '1'

        expect(person.float_data).to eq 1.0

        person.save
        person.reload

        expect(person.float_data).to eq 1.0
      end

      it 'defines a time attribute' do
        Vault::Rails.logical.write("transit/keys/dummy_people_time_data")

        time = Time.parse('05:10:15 UTC')

        person = Person.new
        person.time_data = time

        person.save
        person.reload

        person_time = person.time_data.utc

        expect(person_time.hour).to eq time.hour
        expect(person_time.min).to eq time.min
        expect(person_time.sec).to eq time.sec
      end

      if Vault::Rails.latest?
        it 'raises an error with unknown attribute type' do
          expect do
            Person.vault_attribute :unrecognized_attr, type: :unrecognized
          end.to raise_error RuntimeError, /Unrecognized attribute type/
        end

        it 'defines a default serialzer if it has one for the type' do
          time_data_vault_options = TypedPerson.__vault_attributes[:time_data]
          expect(time_data_vault_options[:serializer]).to eq Vault::Rails::Serializers::TimeSerializer

          integer_data_vault_options = TypedPerson.__vault_attributes[:integer_data]
          expect(integer_data_vault_options[:serializer]).to eq Vault::Rails::Serializers::IntegerSerializer

          float_data_vault_options = TypedPerson.__vault_attributes[:float_data]
          expect(float_data_vault_options[:serializer]).to eq Vault::Rails::Serializers::FloatSerializer

          date_data_vault_options = TypedPerson.__vault_attributes[:date_data]
          expect(date_data_vault_options[:serializer]).to eq Vault::Rails::Serializers::DateSerializer

          date_time_data_vault_options = TypedPerson.__vault_attributes[:date_time_data]
          expect(date_time_data_vault_options[:serializer]).to eq Vault::Rails::Serializers::DateTimeSerializer
        end

        it 'does not add a default serialzer if it does not have one for the type' do
          string_data_vault_options = TypedPerson.__vault_attributes[:string_data]
          expect(string_data_vault_options[:serializer]).to eq Vault::Rails::Serializers::StringSerializer

          decimal_data_vault_options = TypedPerson.__vault_attributes[:decimal_data]
          expect(decimal_data_vault_options[:serializer]).to be_nil

          text_data_vault_options = TypedPerson.__vault_attributes[:text_data]
          expect(text_data_vault_options[:serializer]).to be_nil
        end
      end

      it 'allows overriding the default serialzer via the `serializer` option' do
        custom_date_time_data_vault_options = TypedPerson.__vault_attributes[:custom_date_time_data]
        expect(custom_date_time_data_vault_options[:serializer]).not_to eq Vault::Rails::Serializers::DateTimeSerializer
        expect(custom_date_time_data_vault_options[:serializer]).to eq Vault::Rails::Serializers::DateSerializer
      end

      it 'allows overriding the default serializer via the `encode` and `decode` options' do
        custom_float_data_vault_options = TypedPerson.__vault_attributes[:custom_float_data]
        expect(custom_float_data_vault_options[:serializer]).not_to eq Vault::Rails::Serializers::FloatSerializer
        # we can't reasonably assert on the value of serializer, so we'll
        # check what it does instead
        expect(custom_float_data_vault_options[:serializer].encode(1.5)).to eq '2'
        expect(custom_float_data_vault_options[:serializer].decode('1.5')).to eq 2
      end
    end
  end

  describe '#attributes' do
    let(:person) { Person.new }

    it 'returns all attributes' do
      expect(person.attributes).to eq(
        "business_card" => nil,
        "business_card_encrypted" => nil,
        "cc_encrypted" => nil,
        "county" => nil,
        "county_encrypted" => nil,
        "county_plaintext" => nil,
        "created_at" => nil,
        "credit_card" => nil,
        "date_of_birth" => nil,
        "date_of_birth_encrypted" => nil,
        "date_of_birth_plaintext" => nil,
        "details" => nil,
        "details_encrypted" => nil,
        "driving_licence_number" => nil,
        "driving_licence_number_encrypted" => nil,
        "email" => nil,
        "email_encrypted" => nil,
        "favorite_color" => nil,
        "favorite_color_encrypted" => nil,
        "float_data" => nil,
        "float_data_encrypted" => nil,
        "id" => nil,
        "integer_data" => nil,
        "integer_data_encrypted" => nil,
        "ip_address" => nil,
        "ip_address_encrypted" => nil,
        "name" => nil,
        "non_ascii" => nil,
        "non_ascii_encrypted" => nil,
        'passport_number' => nil,
        "passport_number_encrypted" => nil,
        "ssn" => nil,
        "ssn_encrypted" => nil,
        "state" => nil,
        "state_encrypted" => nil,
        "state_plaintext" => nil,
        "time_data" => nil,
        "time_data_encrypted" => nil,
        "updated_at" => nil
      )
    end
  end

  describe '#unencrypted_attributes' do
    let(:person) { Person.new }

    it 'returns all attributes apart from encrypted fields' do
      expect(person.unencrypted_attributes).to eq(
        'business_card' => nil,
        'county' => nil,
        'county_plaintext' => nil,
        'created_at' => nil,
        'credit_card' => nil,
        'date_of_birth' => nil,
        'date_of_birth_plaintext' => nil,
        'details' => nil,
        'driving_licence_number' => nil,
        'email' => nil,
        'favorite_color' => nil,
        'float_data' => nil,
        'id' => nil,
        'integer_data' => nil,
        'ip_address' => nil,
        'name' => nil,
        'non_ascii' => nil,
        'passport_number' => nil,
        'ssn' => nil,
        'state' => nil,
        'state_plaintext' => nil,
        'time_data' => nil,
        'updated_at' => nil
      )
    end
  end

  describe '#vault_persist_before_save!' do
    context "when not used" do
      # Person hasn't had `vault_persist_before_save!` called on it
      let(:model_class) { Person }

      it "the model has an after_save callback" do
        save_callbacks = model_class._save_callbacks.select do |cb|
          cb.filter == :__vault_persist_attributes!
        end

        expect(save_callbacks.length).to eq 1
        persist_callback = save_callbacks.first

        expect(persist_callback).to be_a ActiveSupport::Callbacks::Callback

        expect(persist_callback.kind).to eq :after
      end

      it 'calls the correct callback' do
        record = model_class.new(ssn: '123-45-6789')
        expect(record).to receive(:__vault_persist_attributes!)

        record.save
      end

      it 'encrypts the attribute if it has been saved' do
        record = model_class.new(ssn: '123-45-6789')
        expect(Vault::Rails).to receive(:encrypt).with('transit', 'dummy_people_ssn', anything, anything, anything).and_call_original

        record.save

        expect(record.ssn_encrypted).not_to be_nil
      end
    end

    context "when used" do
      # EagerPerson has had `vault_persist_before_save!` called on it
      let(:model_class) { EagerPerson }

      it "the model does not have an after_save callback" do
        save_callbacks = model_class._save_callbacks.select do |cb|
          cb.filter == :__vault_persist_attributes!
        end

        expect(save_callbacks.length).to eq 0
      end

      it "the model has a before_save callback" do
        save_callbacks = model_class._save_callbacks.select do |cb|
          cb.filter == :__vault_encrypt_attributes!
        end

        expect(save_callbacks.length).to eq 1
        persist_callback = save_callbacks.first

        expect(persist_callback).to be_a ActiveSupport::Callbacks::Callback

        expect(persist_callback.kind).to eq :before
      end

      it 'calls the correct callback' do
        record = model_class.new(ssn: '123-45-6789')
        expect(record).not_to receive(:__vault_persist_attributes!)
        expect(record).to receive(:__vault_encrypt_attributes!)

        record.save
      end

      it 'encrypts the attribute if it has been saved' do
        record = model_class.new(ssn: '123-45-6789')
        expect(Vault::Rails).to receive(:encrypt).with('transit', 'dummy_people_ssn',anything,anything,anything).and_call_original

        record.save

        expect(record.ssn_encrypted).not_to be_nil
      end
    end
  end
end
