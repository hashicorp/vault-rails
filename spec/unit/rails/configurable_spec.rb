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

  describe '.encoding' do
    context 'when not set explicitly' do
      context 'but there is a rails encoding setting' do
        it 'returns that value' do
          allow(::Rails.application.config).to receive(:encoding).and_return('ISO-8859-1')
          expect(subject.encoding).to eq(Encoding::ISO_8859_1)
        end

        it 'raises an exception if that value is not a valid encoding' do
          allow(::Rails.application.config).to receive(:encoding).and_return('LINEAR_B')
          expect { subject.encoding }.to raise_exception(ArgumentError, /unknown encoding name - LINEAR_B/)
        end
      end

      context 'and there is no rails encoding setting' do
        it 'returns UTF-8' do
          allow(::Rails.application.config).to receive(:encoding).and_return(nil)
          expect(subject.encoding).to eq(Encoding::UTF_8)
        end
      end

      context 'and the gem is not in a rails app' do
        it 'returns UTF-8' do
          hide_const('Rails')
          expect(subject.encoding).to eq(Encoding::UTF_8)
        end
      end
    end

    context 'when configured' do
      it 'returns the configured value' do
        subject.configure do |vault|
          vault.encoding = 'ISO-8859-1'
        end

        expect(subject.encoding).to eq(Encoding::ISO_8859_1)
      end
    end
  end

  context '.encoding=' do
    it 'raises an exception if the supplied value is not a valid encoding' do
      expect { subject.encoding = 'LINEAR_B' }.to raise_exception(ArgumentError, /unknown encoding name - LINEAR_B/)
    end
  end
end
