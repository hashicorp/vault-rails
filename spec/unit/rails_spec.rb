require 'spec_helper'

describe Vault::Rails do
  describe '.serializer_for' do
    it 'accepts a string' do
      serializer = Vault::Rails.serializer_for('json')
      expect(serializer).to be(Vault::Rails::Serializers::JSONSerializer)
    end

    it 'accepts a symbol' do
      serializer = Vault::Rails.serializer_for(:json)
      expect(serializer).to be(Vault::Rails::Serializers::JSONSerializer)
    end

    it 'raises an exception when there is no serializer for the key' do
      expect do
        Vault::Rails.serializer_for(:not_a_serializer)
      end.to raise_error(Vault::Rails::Serializers::UnknownSerializerError) { |e|
        expect(e.message).to match('Unknown Vault serializer `:not_a_serializer`')
      }
    end
  end

  describe '.encrypt' do
    context 'when convergent encryption is enabled' do
      before do
        allow(Vault::Rails).to receive(:enabled?).and_return(true)
        allow(Vault::Rails).to receive(:convergent_encryption_context).and_return('a' * 16)
      end

      it 'sends the correct paramaters to vault client' do
        expected_route = 'path/encrypt/key'
        expected_options = {
          plaintext: Base64.strict_encode64('plaintext'),
          context: Base64.strict_encode64(Vault::Rails.convergent_encryption_context),
          convergent_encryption: true,
          derived: true
        }

        expect(Vault::Rails.client.logical).to receive(:write)
          .with(expected_route, expected_options)
          .and_return(spy('Vault::Secret'))

        Vault::Rails.encrypt('path', 'key', 'plaintext', Vault::Rails.client, true)
      end
    end

    context 'when convergent encryption is disabled' do
      before do
        allow(Vault::Rails).to receive(:enabled?).and_return(true)
      end

      it 'sends the correct paramaters to vault client' do
        expected_route = 'path/encrypt/key'
        expected_options = { plaintext: Base64.strict_encode64('plaintext') }

        expect(Vault::Rails.client.logical).to receive(:write)
          .with(expected_route, expected_options)
          .and_return(spy('Vault::Secret'))

        Vault::Rails.encrypt('path', 'key', 'plaintext', Vault::Rails.client, false)
      end
    end
  end

  describe '.decrypt' do
    context 'when convergent encryption is enabled' do
      before do
        allow(Vault::Rails).to receive(:enabled?).and_return(true)
        allow(Vault::Rails).to receive(:convergent_encryption_context).and_return('a' * 16)
      end

      it 'sends the correct paramaters to vault client' do
        expected_route = 'path/decrypt/key'
        expected_options = {
          ciphertext: 'ciphertext',
          context: Base64.strict_encode64(Vault::Rails.convergent_encryption_context)
        }

        expect(Vault::Rails.client.logical).to receive(:write)
          .with(expected_route, expected_options)
          .and_return(spy('Vault::Secret'))

        Vault::Rails.decrypt('path', 'key', 'ciphertext', Vault::Rails.client, true)
      end
    end

    context 'when convergent encryption is disabled' do
      before do
        allow(Vault::Rails).to receive(:enabled?).and_return(true)
      end

      it 'sends the correct paramaters to vault client' do
        expected_route = 'path/decrypt/key'
        expected_options = { ciphertext: 'ciphertext' }

        expect(Vault::Rails.client.logical).to receive(:write)
          .with(expected_route, expected_options)
          .and_return(spy('Vault::Secret'))

        Vault::Rails.decrypt('path', 'key', 'ciphertext', Vault::Rails.client, false)
      end
    end
  end
end
