require 'spec_helper'

describe Vault::Rails::Serializers::JSONSerializer do
  it 'encodes values to strings' do
    expect(subject.encode({"foo" => "bar", "baz" => 1})).to eq '{"foo":"bar","baz":1}'
  end

  it 'decodes values from strings' do
    expect(subject.decode('{"foo":"bar","baz":1}')).to eq({"foo" => "bar", "baz" => 1})
  end
end
