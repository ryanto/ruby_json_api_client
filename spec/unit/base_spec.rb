require 'spec_helper'

describe RubyJsonApiClient::Base do
  class Person < RubyJsonApiClient::Base
    field :name, :string
    validates :name, presence: true
  end

  describe :field do
    it "should setup attributes for the model" do
      person = Person.new
      person.name = 'ryan'
      expect(person.name).to eq 'ryan'
    end

    context "that has validations" do
      context "that fail" do
        subject { Person.new.valid? }
        it { should eq(false) }
      end

      context "that pass" do
        subject { Person.new(name: 'ryan').valid? }
        it { should eq(true) }
      end
    end
  end

  describe :identifer do
    it "should default to id" do
      expect(Person._identifier).to eq :id
    end

    it "should be able to change the identifier" do
      class Thing < RubyJsonApiClient::Base
        identifier :uuid
      end

      expect(Thing._identifier).to eq :uuid
    end
  end

  describe :belongs_to do

  end

  describe :has_many do

  end

  describe :persisted? do
    it "should be persisted if it has an id" do
      person = Person.new
      person.instance_variable_set(:@id, 1)
      expect(person.persisted?).to eql(true)
    end

    it "should not be persisted if there is no id" do
      expect(Person.new.persisted?).to eql(false)
    end
  end
end
