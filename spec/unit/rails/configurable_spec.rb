require "spec_helper"

describe Vault::Rails::Configurable do
  subject do
    Class.new.tap do |c|
      c.class.instance_eval do
        include Vault::Rails::Configurable
      end
    end
  end

  describe '.in_memory_warnings_enabled?' do
    context 'when unconfigured' do
      it 'returns true' do
        expect(subject.in_memory_warnings_enabled?).to eq true
      end
    end

    context 'when configured as on' do
      before do
        subject.configure do |vault|
          vault.in_memory_warnings_enabled = true
        end
      end

      it 'returns true' do
        expect(subject.in_memory_warnings_enabled?).to eq true
      end
    end

    context 'when configured as off' do
      before do
        subject.configure do |vault|
          vault.in_memory_warnings_enabled = false
        end
      end

      it 'returns false' do
        expect(subject.in_memory_warnings_enabled?).to eq false
      end
    end
  end
end
