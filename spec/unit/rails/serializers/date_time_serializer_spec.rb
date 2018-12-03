require 'spec_helper'

describe Vault::Rails::Serializers::DateTimeSerializer do
  it 'encodes values to strings' do
    expect(subject.encode(DateTime.new(1999, 1, 1, 10, 11, 12.134, '0'))).to eq '1999-01-01T10:11:12.134+00:00'
  end

  it 'decodes values from strings' do
    expect(subject.decode('1999-12-31T20:21:22.234+00:00')).to eq DateTime.new(1999, 12, 31, 20, 21, 22.234, '0')
  end
end
