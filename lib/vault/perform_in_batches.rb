module Vault
  class PerformInBatches
    def initialize(attribute, options)
      @attribute  = attribute

      @key        = options[:key]
      @path       = options[:path]
      @serializer = options[:serializer]
      @column     = options[:encrypted_column]
      @convergent = options[:convergent]
    end

    def encrypt(records, plaintexts)
      raise 'Batch Operations work only with convergent attributes' unless @convergent

      raw_plaintexts = serialize(plaintexts)

      ciphertexts = Vault::Rails.batch_encrypt(path, key, raw_plaintexts, Vault.client)

      records.each_with_index do |record, index|
        record.send("#{column}=", ciphertexts[index])
        record.save
      end
    end

    def decrypt(records)
      raise 'Batch Operations work only with convergent attributes' unless @convergent

      ciphertexts = records.map { |record| record.send(column) }

      raw_plaintexts = Vault::Rails.batch_decrypt(path, key, ciphertexts, Vault.client)
      plaintexts = deserialize(raw_plaintexts)

      records.each_with_index do |record, index|
        record.__vault_loaded_attributes << attribute

        record.write_attribute(attribute, plaintexts[index])
      end
    end

    private

    attr_reader :key, :path, :serializer, :column, :attribute

    def serialize(plaintexts)
      return plaintexts unless serializer

      plaintexts.map { |plaintext| serializer.encode(plaintext) }
    end

    def deserialize(plaintexts)
      return plaintexts unless serializer

      plaintexts.map { |plaintext| serializer.decode(plaintext) }
    end
  end
end
