require 'spec_helper'

describe Vault::Rails::Serializers::FloatSerializer do
  it 'encodes values to strings' do
    expect(subject.encode(1.0)).to eq '1.0'
    expect(subject.encode(42.00001)).to eq '42.00001'
    expect(subject.encode(435345.40035)).to eq '435345.40035'
  end

  it 'decodes values from strings' do
    expect(subject.decode('1.0')).to eq 1.0
    expect(subject.decode('42')).to eq 42.0
    expect(subject.decode('435345.40035')).to eq 435345.40035
  end
end
