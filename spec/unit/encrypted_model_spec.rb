require "spec_helper"

describe Vault::EncryptedModel do
  let(:klass) do
    Class.new(ActiveRecord::Base) do
      include Vault::EncryptedModel
    end
  end

  describe ".vault_attribute" do
    it "raises an exception if a serializer and :encode is given" do
      expect {
        klass.vault_attribute(:foo, serializer: :json, encode: ->(r) { r })
      }.to raise_error(Vault::Rails::ValidationFailedError)
    end

    it "raises an exception if a serializer and :decode is given" do
      expect {
        klass.vault_attribute(:foo, serializer: :json, decode: ->(r) { r })
      }.to raise_error(Vault::Rails::ValidationFailedError)
    end

    it "defines a getter" do
      klass.vault_attribute(:foo)
      expect(klass.instance_methods).to include(:foo)
    end

    it "defines a setter" do
      klass.vault_attribute(:foo)
      expect(klass.instance_methods).to include(:foo=)
    end

    it "defines a checker" do
      klass.vault_attribute(:foo)
      expect(klass.instance_methods).to include(:foo?)
    end

    it "defines dirty attribute methods" do
      klass.vault_attribute(:foo)
      expect(klass.instance_methods).to include(:foo_change)
      expect(klass.instance_methods).to include(:foo_changed?)
      expect(klass.instance_methods).to include(:foo_was)
    end
  end

  describe '#vault_persist_before_save!' do
    let(:after_save_dummy_class) do
      Class.new(ActiveRecord::Base) do
        include Vault::EncryptedModel
      end
    end

    let(:before_save_dummy_class) do
      Class.new(ActiveRecord::Base) do
        include Vault::EncryptedModel
        vault_persist_before_save!
      end
    end

    context "when not used" do
      it "the model has an after_save callback" do
        save_callbacks = after_save_dummy_class._save_callbacks.select do |cb|
          cb.filter == :__vault_persist_attributes!
        end

        expect(save_callbacks.length).to eq 1
        persist_callback = save_callbacks.first

        expect(persist_callback).to be_a ActiveSupport::Callbacks::Callback

        expect(persist_callback.kind).to eq :after
      end
    end

    context "when used" do
      it "the model does not have a after_save callback" do
        save_callbacks = before_save_dummy_class._save_callbacks.select do |cb|
          cb.filter == :__vault_persist_attributes!
        end

        expect(save_callbacks.length).to eq 0
      end

      it "the model has a before_save callback" do
        save_callbacks = before_save_dummy_class._save_callbacks.select do |cb|
          cb.filter == :__vault_encrypt_attributes!
        end

        expect(save_callbacks.length).to eq 1
        persist_callback = save_callbacks.first

        expect(persist_callback).to be_a ActiveSupport::Callbacks::Callback

        expect(persist_callback.kind).to eq :before
      end
    end
  end
end
