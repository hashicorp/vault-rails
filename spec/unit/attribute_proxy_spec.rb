require 'spec_helper'

RSpec.describe 'vault_attribute_proxy' do
  let(:person) { Person.new }

  context 'with encrypted_attribute_only false' do
    it 'fills both attributes' do
      county = 'Orange'
      person.county = county

      expect(person.county).to eq county
      expect(person.county_plaintext).to eq county
    end

    it 'reads first from the encrypted attribute' do
      person.county_plaintext = 'Yellow'
      expect(person.county).to eq('Yellow')
    end

    it 'reads from the plain text attribute when encrypted attribute is not available' do
      person.county = 'Blue'
      person.county_plaintext = nil

      expect(person.county).to eq('Blue')
    end
  end

  context 'with encrypted_attribute_only true' do
    it 'fills only the encrypted attribute' do
      person.state = 'California'

      expect(person.state_plaintext).to eq 'California'
      expect(person.read_attribute(:state)).to be_nil
    end

    it 'reads first from the encrypted attribute' do
      person.state_plaintext = 'New York'
      expect(person.state).to eq 'New York'
    end

    it 'returns nil when encrypted attribute is not available' do
      person.state = 'Florida'
      person.state_plaintext = nil

      expect(person.state).to be_nil
    end
  end
end
