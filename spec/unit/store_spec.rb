require 'spec_helper'

describe RubyJsonApiClient::Store do
  class Person < RubyJsonApiClient::Base
    field :firstname
    field :lastname
  end

  describe :register_adapter do
    context "with name only" do
      subject { RubyJsonApiClient::Store.register_adapter(:json_api) }
      its(:klass) { should eq(RubyJsonApiClient::JsonApiAdapter) }
      its(:options) { should eq({}) }
    end

    context "with name and options" do
      subject do
        RubyJsonApiClient::Store.register_adapter(:json_api, {
          hostname: 'www.example.com'
        })
      end

      its(:klass) { should eq(RubyJsonApiClient::JsonApiAdapter) }
      its(:options) { should == { hostname: 'www.example.com' } }
    end

    context "with name and klass" do
      subject do
        RubyJsonApiClient::Store.register_adapter(:asdf, RubyJsonApiClient::JsonApiAdapter)
      end

      its(:klass) { should eq(RubyJsonApiClient::JsonApiAdapter) }
      its(:options) { should eq({}) }
    end

    context "with name, klass, and options" do
      subject do
        RubyJsonApiClient::Store.register_adapter(:asdf, RubyJsonApiClient::JsonApiAdapter, {
          hostname: 'www.example.com'
        })
      end

      its(:klass) { should eq(RubyJsonApiClient::JsonApiAdapter) }
      its(:options) { should eq({ hostname: 'www.example.com' }) }
    end
  end

  describe :register_serializer do
    context "with name only" do
      subject { RubyJsonApiClient::Store.register_serializer(:json_api) }
      its(:klass) { should eq(RubyJsonApiClient::JsonApiSerializer) }
    end

    context "with name and class" do
      subject { RubyJsonApiClient::Store.register_serializer(:asdf, RubyJsonApiClient::JsonApiSerializer) }
      its(:klass) { should eq(RubyJsonApiClient::JsonApiSerializer) }
    end
  end

  describe :get_adapter do
    context "from a store with no adapters" do
      subject { RubyJsonApiClient::Store.get_adapter(:does_not_exist) }
      it { should be_nil }
    end

    context "from a store with a registered adapter" do
      before(:each) do
        RubyJsonApiClient::Store.register_adapter(:json_api)
      end

      subject { RubyJsonApiClient::Store.get_adapter(:json_api) }
      it { should_not be_nil }
      it { should be_instance_of(RubyJsonApiClient::JsonApiAdapter) }
    end
  end

  describe :get_serializer do
    context "from a store with no serializer" do
      subject { RubyJsonApiClient::Store.get_serializer(:does_not_exist) }
      it { should be_nil }
    end

    context "from a store with a registered serializer" do
      before(:each) do
        RubyJsonApiClient::Store.register_serializer(:json_api)
      end

      subject { RubyJsonApiClient::Store.get_serializer(:json_api) }
      it { should_not be_nil }
      it { should be_instance_of(RubyJsonApiClient::JsonApiSerializer) }
    end
  end

  let(:store) do
    RubyJsonApiClient::Store.new(format: :json_api)
  end

  describe :initialize do
    before(:each) do
      RubyJsonApiClient::Store.register_adapter(:json_api)
      RubyJsonApiClient::Store.register_serializer(:json_api)
    end

    context "the default adapter" do
      subject { store.default_adapter }
      it { should be_instance_of(RubyJsonApiClient::JsonApiAdapter) }
    end

    context "the default serializer" do
      subject { store.default_serializer }
      it { should be_instance_of(RubyJsonApiClient::JsonApiSerializer) }
      its(:store) { should eq(store) }
    end
  end

  describe :find do

    let(:person) { Person.new }

    before(:each) do
      RubyJsonApiClient::Store.register_adapter(:json_api)
      RubyJsonApiClient::Store.register_serializer(:json_api)

      allow(store.default_adapter).to receive(:find)
        .with(Person, 1)
        .and_return("{}")

      allow(store.default_serializer).to receive(:extract_single)
        .with(Person, 1, "{}")
        .and_return(person)
    end

    it "should should find a person" do
      expect(store.find(Person, 1)).to eq(person)
    end

    it "should set the response inside the model" do
      person = store.find(Person, 1)
      expect(person.__origin__).to eq("{}")
    end
  end

  describe :query do
    let(:person) { Person.new }
    let(:people) { [person, person] }
    let(:result) { store.query(Person, {}) }

    before(:each) do
      RubyJsonApiClient::Store.register_adapter(:json_api)
      RubyJsonApiClient::Store.register_serializer(:json_api)

      allow(store.default_adapter).to receive(:find_many)
        .with(Person, {})
        .and_return("{}")

      allow(store.default_serializer).to receive(:extract_many)
        .with(Person, "{}")
        .and_return(people)
    end

    subject { result }

    it { should have(2).people }
    it { should include(person) }

    it "should set the response on the collection" do
      expect(result.__origin__).to eq("{}")
    end
  end

  describe :load_collection do
    before(:each) do
      RubyJsonApiClient::Store.register_adapter(:json_api)
      RubyJsonApiClient::Store.register_serializer(:json_api)
    end

    let(:serializer) { store.default_serializer }
    let(:adapter) { store.default_adapter }

    it "should use the adapter and serializer to load the collection" do
      expect(adapter).to receive(:get)
        .with("http://example.com/testings")
        .and_return("[]")

      expect(serializer).to receive(:extract_many)
        .with(Person, "[]")
        .and_return([])

      store.load_collection(Person, "http://example.com/testings")
    end
  end

  describe :load_single do
    before(:each) do
      RubyJsonApiClient::Store.register_adapter(:json_api)
      RubyJsonApiClient::Store.register_serializer(:json_api)
    end

    let(:serializer) { store.default_serializer }
    let(:adapter) { store.default_adapter }

    it "should use the adapter and serializer to load the model" do
      expect(adapter).to receive(:get)
        .with("http://example.com/testings/1")
        .and_return("{}")

      expect(serializer).to receive(:extract_single)
        .with(Person, 1, "{}")
        .and_return(OpenStruct.new)

      store.load_single(Person, 1, "http://example.com/testings/1")
    end
  end

  describe :reload do
    let(:person) { Person.new(id: 1) }

    before(:each) do
      expect(store).to receive(:find)
        .with(Person, 1)
        .and_return(
          Person.new(id: 1, firstname: 'test')
        )

      store.reload(person)
    end

    subject { person }

    it { should eql(person) }
    its(:firstname) { should eq('test') }
    its(:id) { should eq(1) }
  end

  describe :merge do
    let(:person1) { Person.new(firstname: 'ryan', lastname: 'no') }
    let(:person2) { Person.new(firstname: 'new') }

    subject { store.merge(person1, person2) }

    it { should be_instance_of(Person) }
    its(:firstname) { should eq('new') }
    its(:lastname) { should be_nil }
  end
end
