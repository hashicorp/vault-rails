require 'spec_helper'

describe Vault::Rails::Serializers::JSONSerializer do
  context '.encode' do
    it 'encodes values to strings' do
      expect(subject.encode({"foo" => "bar", "baz" => 1})).to eq '{"foo":"bar","baz":1}'
    end

    it 'returns values already encoded as a JSON string' do
      expect(subject.encode('{"anonymised":true}')).to eq('{"anonymised":true}')
    end
  end

  context '.decode' do
    it 'decodes values from strings' do
      expect(subject.decode('{"foo":"bar","baz":1}')).to eq({"foo" => "bar", "baz" => 1})
    end
  end
end
