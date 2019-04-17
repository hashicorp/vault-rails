require 'spec_helper'

describe Vault::PerformInBatches do
  describe '#encrypt' do
    context 'non-convergent attribute' do
      let(:options) do
        {
          key: 'test_key',
          path: 'test_path',
          column: 'test_attribute_encrypted',
          convergent: false
        }
      end

      it 'raises an exception for non-convergent attributes' do
        attribute = 'test_attribute'
        records = [double(:first_object, save: true), double(:second_object, save: true)]
        plaintexts = %w(plaintext1 plaintext2)

        expect do
          Vault::PerformInBatches.new(attribute, options).encrypt(records, plaintexts)
        end.to raise_error 'Batch Operations work only with convergent attributes'
      end
    end

    context 'convergent attribute' do
      let(:options) do
        {
          key: 'test_key',
          path: 'test_path',
          encrypted_column: 'test_attribute_encrypted',
          convergent: true
        }
      end

      it 'encrypts one attribute for a batch of records and saves it' do
        attribute = 'test_attribute'

        first_record = double(save: true)
        second_record = double(save: true)
        records = [first_record, second_record]

        plaintexts = %w(plaintext1 plaintext2)


        expect(Vault::Rails).to receive(:batch_encrypt)
          .with('test_path', 'test_key', %w(plaintext1 plaintext2), Vault.client)
          .and_return(%w(ciphertext1 ciphertext2))

        expect(first_record).to receive('test_attribute_encrypted=').with('ciphertext1')
        expect(second_record).to receive('test_attribute_encrypted=').with('ciphertext2')

        Vault::PerformInBatches.new(attribute, options).encrypt(records, plaintexts)
      end

      context 'with validation turned off' do
        it 'encrypts one attribute for a batch of records and saves it without validations' do
          attribute = 'test_attribute'

          first_record = double(save: true)
          second_record = double(save: true)
          records = [first_record, second_record]

          plaintexts = %w(plaintext1 plaintext2)


          expect(Vault::Rails).to receive(:batch_encrypt)
            .with('test_path', 'test_key', %w(plaintext1 plaintext2), Vault.client)
            .and_return(%w(ciphertext1 ciphertext2))

          expect(first_record).to receive('test_attribute_encrypted=').with('ciphertext1')
          expect(second_record).to receive('test_attribute_encrypted=').with('ciphertext2')

          expect(first_record).to receive(:save).with(validate: false)
          expect(second_record).to receive(:save).with(validate: false)

          Vault::PerformInBatches.new(attribute, options).encrypt(records, plaintexts, validate: false)
        end
      end

      context 'with given serializer' do
        let(:options) do
          {
            key: 'test_key',
            path: 'test_path',
            encrypted_column: 'test_attribute_encrypted',
            serializer: Vault::Rails::Serializers::IntegerSerializer,
            convergent: true
          }
        end

        it 'encrypts one attribute for a batch of records and saves it' do
          attribute = 'test_attribute'

          first_record = double(save: true)
          second_record = double(save: true)
          records = [first_record, second_record]

          plaintexts = [100, 200]

          expect(Vault::Rails).to receive(:batch_encrypt)
            .with('test_path', 'test_key', %w(100 200), Vault.client)
            .and_return(%w(ciphertext1 ciphertext2))

          expect(first_record).to receive('test_attribute_encrypted=').with('ciphertext1')
          expect(second_record).to receive('test_attribute_encrypted=').with('ciphertext2')

          Vault::PerformInBatches.new(attribute, options).encrypt(records, plaintexts)
        end
      end
    end
  end

  describe '#decrypt' do
    context 'non-convergent attribute' do
      let(:options) do
        {
          key: 'test_key',
          path: 'test_path',
          column: 'test_attribute_encrypted',
          convergent: false
        }
      end

      it 'raises an exception for non-convergent attributes' do
        attribute = 'test_attribute'
        records = [double(:first_object, save: true), double(:second_object, save: true)]
        plaintexts = %w(plaintext1 plaintext2)

        expect do
          Vault::PerformInBatches.new(attribute, options).encrypt(records, plaintexts)
        end.to raise_error 'Batch Operations work only with convergent attributes'
      end
    end

    context 'convergent attribute' do
      let(:options) do
        {
          key: 'test_key',
          path: 'test_path',
          encrypted_column: 'test_attribute_encrypted',
          convergent: true
        }
      end

      it 'decrypts one attribute for a batch of records and loads it' do
        attribute = 'test_attribute'

        first_record = double(test_attribute_encrypted: 'ciphertext1')
        second_record = double(test_attribute_encrypted: 'ciphertext2')
        records = [first_record, second_record]

        expect(Vault::Rails).to receive(:batch_decrypt)
          .with('test_path', 'test_key', %w(ciphertext1 ciphertext2), Vault.client)
          .and_return(%w(plaintext1 plaintext2))

        if Vault::Rails.latest?
          first_record_loaded_attributes = []
          allow(first_record).to receive('__vault_loaded_attributes').and_return(first_record_loaded_attributes)
          second_record_loaded_attributes = []
          allow(second_record).to receive('__vault_loaded_attributes').and_return(second_record_loaded_attributes)
        end

        if Vault::Rails.latest?
          expect(first_record).to receive('write_attribute').with('test_attribute', 'plaintext1')
          expect(second_record).to receive('write_attribute').with('test_attribute', 'plaintext2')
        else
          expect(first_record).to receive('instance_variable_set').with('@test_attribute', 'plaintext1')
          expect(second_record).to receive('instance_variable_set').with('@test_attribute', 'plaintext2')
        end

        Vault::PerformInBatches.new(attribute, options).decrypt(records)

        if Vault::Rails.latest?
          expect(first_record_loaded_attributes).to include(attribute)
          expect(second_record_loaded_attributes).to include(attribute)
        end
      end

      context 'with given serializer' do
        let(:options) do
          {
            key: 'test_key',
            path: 'test_path',
            encrypted_column: 'test_attribute_encrypted',
            serializer: Vault::Rails::Serializers::IntegerSerializer,
            convergent: true
          }
        end

        it 'decrypts one attribute for a batch of records and loads it' do
          attribute = 'test_attribute'

          first_record = double(test_attribute_encrypted: 'ciphertext1')
          second_record = double(test_attribute_encrypted: 'ciphertext2')
          records = [first_record, second_record]

          expect(Vault::Rails).to receive(:batch_decrypt)
            .with('test_path', 'test_key', %w(ciphertext1 ciphertext2), Vault.client)
            .and_return(%w(100 200))

          if Vault::Rails.latest?
            first_record_loaded_attributes = []
            allow(first_record).to receive('__vault_loaded_attributes').and_return(first_record_loaded_attributes)
            second_record_loaded_attributes = []
            allow(second_record).to receive('__vault_loaded_attributes').and_return(second_record_loaded_attributes)
          end

          if Vault::Rails.latest?
            expect(first_record).to receive('write_attribute').with('test_attribute', 100)
            expect(second_record).to receive('write_attribute').with('test_attribute', 200)
          else
            expect(first_record).to receive('instance_variable_set').with('@test_attribute', 100)
            expect(second_record).to receive('instance_variable_set').with('@test_attribute', 200)
          end

          Vault::PerformInBatches.new(attribute, options).decrypt(records)

          if Vault::Rails.latest?
            expect(first_record_loaded_attributes).to include(attribute)
            expect(second_record_loaded_attributes).to include(attribute)
          end
        end
      end
    end
  end
end
