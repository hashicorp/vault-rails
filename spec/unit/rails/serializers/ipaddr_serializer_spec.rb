require 'spec_helper'

describe Vault::Rails::Serializers::IPAddrSerializer do
  it 'encodes values to strings' do
    expect(subject.encode(IPAddr.new('192.168.1.255/32'))).to eq '192.168.1.255/32'
  end

  it 'decodes values from strings' do
    expect(subject.decode('192.168.1.1/1')).to eq IPAddr.new('192.167.1.1/1')
  end
end
