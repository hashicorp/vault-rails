# frozen_string_literal: true

require 'spec_helper'
require './lib/vault/transit_json_codec.rb'

RSpec.describe Vault::TransitJsonCodec do

  subject(:codec) { described_class.new(encryption_key) }
  let(:encryption_key) { 'blobbykey' }

  before do
    Vault.configure { |c| c.address = Vault.client.address }
  end

  describe '#encrypt' do
    context 'when plaintext is blank' do
      let(:plaintext) { nil }

      it 'returns nil' do
        expect(codec.encrypt(plaintext)).to be_nil
      end
    end

    context 'when plaintext is empty' do
      let(:plaintext) { '' }

      it 'returns nil' do
        expect(codec.encrypt(plaintext)).to be_nil
      end
    end

    context 'when plaintext is present' do
      let(:plaintext) { 'blobby' }

      context 'when encryption fails' do
        before do
          allow(Vault).to receive(:logical).and_raise(StandardError, 'Oh no!')
        end

        it 're-raises error' do
          expect { codec.encrypt(plaintext) }.to raise_error(StandardError)
        end
      end

      it 'encrypts the field' do
        expect(codec.encrypt(plaintext)).to start_with('vault:v1:')
      end
    end
  end

  describe '#decrypt' do

    context 'when ciphertext is nil' do
      let(:ciphertext) { nil }

      it 'returns nil' do
        expect(codec.decrypt(ciphertext)).to be_nil
      end
    end

    context 'when ciphertext is empty' do
      let(:ciphertext) { '' }

      it 'returns nil' do
        expect(codec.decrypt(ciphertext)).to be_nil
      end
    end

    context 'when ciphertext is present' do
      let(:plaintext) { 'blobby' }

      context 'when decoding fails' do
        before do
          allow(Vault).to receive(:logical).and_raise(StandardError, 'Oh no!')
        end

        it 're-raises error' do
          expect { codec.decrypt(plaintext) }.to raise_error(StandardError)
        end
      end

      it 'decrypts an encrypted field' do
        encrypted_text = codec.encrypt(plaintext)
        expect(codec.decrypt(encrypted_text)).to eq(plaintext)
      end
    end
  end
end
