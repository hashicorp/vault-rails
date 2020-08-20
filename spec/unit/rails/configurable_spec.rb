require "spec_helper"

describe Vault::Rails::Configurable do
  subject do
    Class.new.tap do |c|
      c.class.instance_eval do
        include Vault::Rails::Configurable
      end
    end
  end

  describe '.application' do
    context 'when unconfigured' do
      it 'raises exception' do
        expect {
          subject.application
        }.to raise_error(RuntimeError)
      end
    end

    context 'when configured' do
      before do
        subject.configure do |vault|
          vault.application = "dummy"
        end
      end

      it 'returns the application' do
        expect(subject.application).to eq "dummy"
      end
    end

    context 'falls back to ENV' do
      before do
        ENV["VAULT_RAILS_APPLICATION"] = "envdummy"
      end
      after do
        ENV.delete("VAULT_RAILS_APPLICATION")
      end

      it 'returns the application defined in ENV' do
        expect(subject.application).to eq "envdummy"
      end
    end
  end

  describe '.enabled' do
    context 'when unconfigured' do
      it 'returns false' do
        expect(subject.enabled?).to eq false
      end
    end

    context 'when configured' do
      it 'returns true' do
        subject.configure do |vault|
          vault.enabled = true
        end
        expect(subject.enabled?).to eq true
      end

      it 'returns false' do
        subject.configure do |vault|
          vault.enabled = false
        end
        expect(subject.enabled?).to eq false
      end
    end

    context 'falls back to ENV' do
      after do
        ENV.delete("VAULT_RAILS_ENABLED")
      end

      it 'returns false' do
        ENV["VAULT_RAILS_ENABLED"] = "false"
        expect(subject.enabled?).to eq false
      end

      it 'returns true' do
        ENV["VAULT_RAILS_ENABLED"] = "true"
        expect(subject.enabled?).to eq true
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
