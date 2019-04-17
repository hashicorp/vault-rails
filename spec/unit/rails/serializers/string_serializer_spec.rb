require 'spec_helper'

describe Vault::Rails::Serializers::StringSerializer do
  context 'blank values' do
    it 'encodes blank values without changing them' do
      expect(subject.encode(nil)).to eq nil
    end
  end

  it 'encodes values to strings' do
    expect(subject.encode({a: 3})).to eq "{:a=>3}"
  end

  it 'decodes the value by simply returing it' do
    expect(subject.decode('foo')).to eq 'foo'
  end
end
