require 'spec_helper'

describe Vault::Rails::Serializers::DateSerializer do
  it 'encodes values to strings' do
    expect(subject.encode(Date.new(1999, 1, 1))).to eq '1999-01-01'
  end

  it 'decodes values from strings' do
    expect(subject.decode('1999-12-31')).to eq Date.new(1999, 12, 31)
  end
end

