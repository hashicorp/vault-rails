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

    it "raises an exception if a proc is passed to :context without an arity of 1" do
      expect {
        klass.vault_attribute(:foo, context: ->() { })
      }.to raise_error(Vault::Rails::ValidationFailedError, /1 argument/i)
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
      expect(Person.new).to respond_to(:ssn_change)
      expect(Person.new).to respond_to(:ssn_changed?)
      expect(Person.new).to respond_to(:ssn_was)
    end
  end
end
