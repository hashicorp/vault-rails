require 'spec_helper'

RSpec.describe Vault::Rails do
  describe "#memory_key_for" do
    input_examples = [
      ["path", "key"],
      ["path", "key", "context"],
      ["a_really_long_path", "a_really_long_key"],
      ["a_really_long_path", "a_really_long_key", "a_really_long_context"],
    ]

    input_examples.each do |path, key, encryption_context|
      context "with path=#{path}, key=#{key}, context=#{encryption_context}" do
        it "returns exactly 16 bytes as required by OpenSSL AES 128" do
          memory_key = Vault::Rails.send(
            :memory_key_for, path, key, context: encryption_context
          )
          expect(memory_key.bytesize).to eq(16)
        end
      end
    end

    it "returns unique keys for different paths, keys, and contexts" do
      memory_keys = input_examples.map { |path, key, encryption_context|
        Vault::Rails.send(
          :memory_key_for, path, key, context: encryption_context
        )
      }

      expect(memory_keys).to match_array(memory_keys.uniq)
    end
  end
end
