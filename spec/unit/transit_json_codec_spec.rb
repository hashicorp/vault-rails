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

  describe '#batch_encrypt' do
    context 'when plaintexts array is empty' do
      it 'returns empty array' do
        expect(codec.batch_encrypt([])).to eq([])
        expect(codec.batch_encrypt(nil)).to eq([])
      end
    end

    context 'when plaintexts are present' do
      let(:plaintexts) { ['some text', 'other text'] }

      it 'returns array of encrypted values' do
        ciphertexts = codec.batch_encrypt(plaintexts)
        expect(ciphertexts).not_to be_blank
        expect(ciphertexts.length).to eq(plaintexts.length)
        ciphertexts.each { |ciphertext| expect(ciphertext).to start_with('vault:v1:') }
        ciphertexts.each_with_index { |ciphertext, i| expect(codec.decrypt(ciphertext)).to eq(plaintexts[i]) }
      end

      context 'when encryption fails' do
        before do
          allow(Vault).to receive(:logical).and_raise(StandardError, 'Oh no!')
        end

        it 're-raises error' do
          expect { codec.batch_encrypt(plaintexts) }.to raise_error(StandardError)
        end
      end
    end
  end

  describe '#batch_decrypt' do
    context 'when ciphertexts array is empty' do
      it 'returns empty array' do
        expect(codec.batch_decrypt([])).to eq([])
        expect(codec.batch_decrypt(nil)).to eq([])
      end
    end

    context 'when ciphertexts are present' do
      let(:plaintexts) { ['some text', 'other text'] }
      let(:ciphertexts) { codec.batch_encrypt(plaintexts) }

      it 'returns array of decrypted values' do
        decrypted = codec.batch_decrypt(ciphertexts)
        expect(decrypted).not_to be_blank
        expect(decrypted.length).to eq(plaintexts.length)
        expect(decrypted).to eq(plaintexts)
      end

      context 'when decryption fails' do
        before do
          allow(Vault).to receive(:logical).and_raise(StandardError, 'Oh no!')
        end

        it 're-raises error' do
          expect { codec.batch_decrypt(plaintexts) }.to raise_error(StandardError)
        end
      end
    end
  end

end
