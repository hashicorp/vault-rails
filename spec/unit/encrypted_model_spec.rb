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
        klass.vault_attribute :foo,
          serializer: :json,
          default: {},
          encode: ->(r) { r }
      }.to raise_error(
        Vault::Rails::ValidationFailedError,
        %r{cannot use a custom encoder/decoder}i
      )
    end

    it "raises an exception if a serializer and :decode is given" do
      expect {
        klass.vault_attribute :foo,
          serializer: :json,
          default: {},
          decode: ->(r) { r }
      }.to raise_error(
        Vault::Rails::ValidationFailedError,
        %r{cannot use a custom encoder/decoder}i
      )
    end

    it "raises an exception if a proc is passed to :context without an arity of 1" do
      expect {
        klass.vault_attribute :foo,
          context: ->() { }
      }.to raise_error(
        Vault::Rails::ValidationFailedError,
        %r{must take 1 argument}i
      )
    end

    it "raises an exception if a serializer is given without a :default" do
      expect {
        klass.vault_attribute :foo,
          serializer: :json
      }.to raise_error(
        Vault::Rails::ValidationFailedError,
        %r{use of a built-in serializer requires}i
      )
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
end
