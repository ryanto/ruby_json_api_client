require 'spec_helper'

describe RubyJsonApiClient::AmsSerializer do
  let(:serializer) { RubyJsonApiClient::AmsSerializer.new }

  class Person < RubyJsonApiClient::Base
    field :name
  end

  class Item < RubyJsonApiClient::Base
    field :name
  end

  class CellPhone < RubyJsonApiClient::Base
    field :number
  end

  describe :transform do
    let(:json) { "{\"testing\":true, \"name\":\"ryan\"}" }
    subject { serializer.transform(json)["testing"] }
    it { should eql(true) }
  end

  describe :extract_single do
    context "will error when" do
      subject { ->{ serializer.extract_single(Person, 1, json) } }

      context "no json root key exists" do
        let(:json) { "{\"name\":\"ryan\"}" }
        it { should raise_error }
      end

      context "no id" do
        let(:json) { "{\"person\": { \"name\":\"ryan\" } }" }
        it { should raise_error }
      end

      context "the id returned is not the id we are looking for" do
        let(:json) { "{\"person\": { \"id\": 2, \"name\":\"ryan\" } }" }
        it { should raise_error }
      end
    end

    context "when payload contains" do
      subject { serializer.extract_single(Person, 1, json) }

      context "string ids" do
        let(:json) { "{\"person\": { \"id\": \"1\", \"name\":\"ryan\" } }" }
        it { should be_instance_of(Person) }
      end

      context "attributes that are defined" do
        let(:json) { "{\"person\": { \"id\": \"1\", \"name\":\"ryan\" } }" }
        it { should be_instance_of(Person) }
        it { should respond_to(:name) }
        its(:name) { should eq('ryan') }
      end

      context "attributes that are not defined" do
        let(:json) { "{\"person\": { \"id\": \"1\", \"unknown\":\"ryan\" } }" }
        it { should be_instance_of(Person) }
        it { should_not respond_to(:unknown) }
      end
    end

    context "using multi worded models" do
      subject { serializer.extract_single(CellPhone, 1, json) }
      let(:model) { subject }


      let(:json) { "{\"cell_phone\": { \"id\": 1, \"number\": \"123-456-7890\" } }" }
      it { should be_instance_of(CellPhone) }
      its(:number) { should eq('123-456-7890') }
    end
  end

  describe :extract_many do
    context "will error when" do
      subject { ->{ serializer.extract_many(Person, json) } }

      context "there is no plural key in the response" do
        let(:json) { "[{ \"id\": 1, \"name\": \"ryan\" }]" }
        it { should raise_error }
      end

      context "there is no array of data" do
        let(:json) { "{ \"id\": 1, \"name\": \"ryan\" }" }
        it { should raise_error }
      end
    end

    context "when payload contains" do
      subject { serializer.extract_many(Person, json) }
      let(:collection) { subject }

      context "multiple records" do
        let(:json) do
          "{ \"people\": [{ \"id\": 1, \"name\": \"ryan\" }, { \"id\": 2, \"name\": \"ryan2\" }] }"
        end

        it { should have(2).items }

        it "should serialize one of the records" do
          expect(collection.first).to respond_to(:name)
          expect(collection.first.name).to eq('ryan')
        end
      end
    end
  end

  describe :extract_many_relationship do

    let(:person) { Person.new }

    it "should extact relationships using links" do
      expect(serializer).to receive(:extract_many_relationship_from_links)
        .with(person, :items, "http://items.test")
        .and_return([])

      person.meta = {
        links: {
          'items' => "http://items.test"
        }
      }

      serializer.extract_many_relationship(
        person,
        :items,
        "{}"
      )
    end

    it "should extract relationships using sideloads" do
      items = "[{ \"id\": 1, \"name\": \"first\" }, { \"id\": 2, \"name\": \"second\" }]"
      response = "{ \"person\": { \"item_ids\": [1] }, \"items\": #{items} }"

      expect(serializer).to receive(:extract_many_relationship_from_sideload)
        .with(person, :items, response)
        .and_return([])

      person.meta = {
        data: {
          'item_ids' => [1]
        }
      }

      serializer.extract_many_relationship(
        person,
        :items,
        response
      )
    end

    it "should not try to extract sideloads if the parent record doesnt have ids" do
      result = serializer.extract_many_relationship(
        person,
        :items,
        "{ \"person\": { }, \"items\": [{\"id\": 1 }] }"
      )

      expect(result).to match_array([])
    end

    it "should give an empty collection when there is no sideload or links present" do
      result = serializer.extract_many_relationship(person, :items, "{ \"person\": { } }")
      expect(result).to match_array([])
    end
  end

  describe :extract_many_relationship_from_links do
    let(:person) { Person.new }

    it "should have the store load the collection" do
      store = double("store")
      serializer.store = store

      expect(store).to receive(:load_collection)
        .with(Item, "http://www.example.com/items")

      serializer.extract_many_relationship_from_links(
        person,
        :items,
        "http://www.example.com/items"
      )
    end
  end

  describe :extract_many_relationship_from_sideload do
    let(:person) do
      Person.new(meta: {
        data: {
          "item_ids" => [2]
        }
      })
    end

    let(:response) do
      {
        person: {
          id: 1,
          item_ids: [2]
        },
        items: [
          { id: 1, name: "test" },
          { id: 2, name: "test 2" }
        ]
      }.to_json
    end

    it "should use extract many to pull the data" do
      expect(serializer).to receive(:extract_many)
        .with(Item, response)
        .and_return([])

      serializer.extract_many_relationship_from_sideload(person, :items, response)
    end

    it "should filter the ids in the relationship" do
      result = serializer.extract_many_relationship_from_sideload(person, :items, response)

      expect(result).to have(1).items
      expect(result.first.id).to eq(2)
    end
  end
end
