require 'spec_helper'

describe Vault::Rails::Serializers::TimeSerializer do
  it 'encodes values to strings' do
    expect(subject.encode(Time.utc(1999, 1, 1, 10, 11, 12, 134000))).to eq '1999-01-01T10:11:12.134Z'
  end

  it 'decodes values from strings' do
    expect(subject.decode('1999-12-31T20:21:22.234Z')).to eq Time.utc(1999, 12, 31, 20, 21, 22, 234000)
  end
end
