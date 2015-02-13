require 'spec_helper'

describe RubyJsonApiClient::Base do
  class Person < RubyJsonApiClient::Base
    field :firstname, :string
    validates :firstname, presence: true
  end

  describe :field do
    it "should setup attributes for the model" do
      person = Person.new
      person.firstname = 'ryan'
      expect(person.firstname).to eq 'ryan'
    end

    context "that has validations" do
      context "that fail" do
        subject { Person.new.valid? }
        it { should eq(false) }
      end

      context "that pass" do
        subject { Person.new(firstname: 'ryan').valid? }
        it { should eq(true) }
      end
    end
  end

  describe :has_field? do
    context "a class with no fields" do
      subject { Nothing.has_field?(:nope) }
      it { should eq(false) }
    end

    context "a class with fields that has the field" do
      subject { Item.has_field?(:name) }
      it { should eq(true) }
    end
  end

  describe :identifer do
    it "should default to id" do
      expect(Person._identifier).to eq :id
    end

    it "should be able to change the identifier" do

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

  describe :new_record? do
    it "should not be a new record if it has an id" do
      person = Person.new
      person.instance_variable_set(:@id, 1)
      expect(person.new_record?).to eql(false)
    end

    it "should be a new record if there is no id" do
      expect(Person.new.new_record?).to eql(true)
    end
  end

  describe :marked_for_destruction? do
    it "should return false by default" do
      expect(!!Person.new.marked_for_destruction?).to eql(false)
    end
  end

  describe :_destroy do
    it "should return false by default" do
      expect(!!Person.new._destroy).to eql(false)
    end
  end

  describe :== do
    context "two objects of different classes" do
      subject { Person.new(id: 1) == Item.new(id: 1) }
      it { should eq(false) }
    end

    context "two objects of the same class but different ids" do
      subject { Person.new(id: 1) == Person.new(id: 2) }
      it { should eq(false) }
    end

    context "two objects with the same klass and id" do
      subject { Person.new(id: 1) == Person.new(id: 1) }
      it { should eq(true) }
    end

    context "the same instance" do
      let(:person) { Person.new(id: 1) }
      subject { person == person }
      it { should eq(true) }
    end

    context "two objects with non standard identifiers" do
      subject { Thing.new(uuid: 'x') == Thing.new(uuid: 'x') }
      it { should eq(true) }
    end
  end
end
