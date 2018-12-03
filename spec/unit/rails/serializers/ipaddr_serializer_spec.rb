require 'spec_helper'

describe Vault::Rails::Serializers::IPAddrSerializer do
  it 'encodes values to strings for IP4 addresses' do
    expect(subject.encode(IPAddr.new('192.168.1.255/32'))).to eq '192.168.1.255/32'
  end

  it 'decodes values from strings for IP4 addresses' do
    expect(subject.decode('192.168.1.1/1')).to eq IPAddr.new('192.168.1.1/1')
  end

  it 'encodes values to strings for IP6 addresses' do
    expect(subject.encode(IPAddr.new('fd12:3456:789a:1::ffff/128'))).to eq 'fd12:3456:789a:1::ffff/128'
  end

  it 'decodes values from strings for IP6 addresses' do
    expect(subject.decode('fd12:3456:789a:1::1/1')).to eq IPAddr.new('fd12:3456:789a:1::1/1')
  end
end
