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

      it 'raises an error with unknown attribute type' do
        expect do
          Person.vault_attribute :unrecognized_attr, type: :unrecognized
        end.to raise_error RuntimeError, /Unrecognized/
      end
    end
  end

  describe '#vault_persist_before_save!' do
    context "when not used" do
      it "the model has an after_save callback" do
        save_callbacks = Person._save_callbacks.select do |cb|
          cb.filter == :__vault_persist_attributes!
        end

        expect(save_callbacks.length).to eq 1
        persist_callback = save_callbacks.first

        expect(persist_callback).to be_a ActiveSupport::Callbacks::Callback

        expect(persist_callback.kind).to eq :after
      end

      it 'calls the correnct callback' do
        eager_person = Person.new(ssn: '123-45-6789')
        expect(eager_person).to receive(:__vault_persist_attributes!)

        eager_person.save
      end
    end

    context "when used" do
      it "the model does not have an after_save callback" do
        save_callbacks = EagerPerson._save_callbacks.select do |cb|
          cb.filter == :__vault_persist_attributes!
        end

        expect(save_callbacks.length).to eq 0
      end

      it "the model has a before_save callback" do
        save_callbacks = EagerPerson._save_callbacks.select do |cb|
          cb.filter == :__vault_encrypt_attributes!
        end

        expect(save_callbacks.length).to eq 1
        persist_callback = save_callbacks.first

        expect(persist_callback).to be_a ActiveSupport::Callbacks::Callback

        expect(persist_callback.kind).to eq :before
      end

      it 'calls the correct callback' do
        eager_person = EagerPerson.new(ssn: '123-45-6789')
        expect(eager_person).not_to receive(:__vault_persist_attributes!)
        expect(eager_person).to receive(:__vault_encrypt_attributes!)

        eager_person.save
      end
    end
  end
end
