require 'spec_helper'

RSpec.describe Vault::Rails::JSONSerializer do
  [
    nil,
    false,
    true,
    "",
    "foo",
    {},
    { "foo" => "bar" },
    [],
    ["foo", "bar"],
    0,
    123,
    0.0,
    0.123,
    0xff,
    123e123
  ].each do |object|
    it "encodes and decodes #{object.inspect}" do
      encoded = described_class.encode(object)
      expect(encoded).to be_a(String)
      decoded = described_class.decode(encoded)
      expect(decoded).to eq(object)
    end
  end

  describe ".decode" do
    subject(:decoded) { described_class.decode(raw) }

    context "with nil" do
      let(:raw) { nil }
      it { is_expected.to eq(nil) }
    end

    context "with an empty string" do
      let(:raw) { "" }
      it { is_expected.to eq(nil) }
    end
  end
end
