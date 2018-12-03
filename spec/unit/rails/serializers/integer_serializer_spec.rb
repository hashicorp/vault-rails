require 'spec_helper'

describe Vault::Rails::Serializers::IntegerSerializer do
  it 'encodes values to strings' do
    expect(subject.encode(1)).to eq '1'
    expect(subject.encode(42)).to eq '42'
    expect(subject.encode(23425)).to eq '23425'
  end

  it 'decodes values from strings' do
    expect(subject.decode('1')).to eq 1
    expect(subject.decode('42')).to eq 42
    expect(subject.decode('23425')).to eq 23425
  end
end
