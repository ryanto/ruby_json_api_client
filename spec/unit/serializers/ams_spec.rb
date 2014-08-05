require 'spec_helper'

describe RubyJsonApiClient::AmsSerializer do
  let(:serializer) { RubyJsonApiClient::AmsSerializer.new }

  describe :transform do
    let(:json) { "{\"testing\":true, \"firstname\":\"ryan\"}" }
    subject { serializer.transform(json)["testing"] }
    it { should eql(true) }
  end

  describe :to_json do
    context "using fields" do
      subject { serializer.to_json(Person.new(firstname: 'ryan')) }
      it do
        should eq({ person: {
          firstname: 'ryan',
          lastname: nil
        }}.to_json)
      end
    end

    context "using a persisted model" do
      subject { serializer.to_json(Person.new(id: 1, firstname: 'ryan')) }
      it do
        should eq({ person: {
          id: 1,
          firstname: 'ryan',
          lastname: nil
        } }.to_json)
      end
    end

    context "using a has one relationship" do
      subject do
        person = Person.new(
          id: 1,
          firstname: 'ryan',
          lastname: nil
        )

        person.item = Item.new(id: 2)
        serializer.to_json(person)
      end

      it do
        should eq({ person: {
          id: 1,
          firstname: 'ryan',
          lastname: nil,
          item_id: 2
        } }.to_json)
      end
    end
  end

  describe :extract_single do
    context "will error when" do
      subject { ->{ serializer.extract_single(Person, 1, json) } }

      context "no json root key exists" do
        let(:json) { "{\"firstname\":\"ryan\"}" }
        it { should raise_error }
      end

      context "no id" do
        let(:json) { "{\"person\": { \"firstname\":\"ryan\" } }" }
        it { should raise_error }
      end

      context "the id returned is not the id we are looking for" do
        let(:json) { "{\"person\": { \"id\": 2, \"firstname\":\"ryan\" } }" }
        it { should raise_error }
      end
    end

    context "when payload contains" do
      subject { serializer.extract_single(Person, 1, json) }

      context "string ids" do
        let(:json) { "{\"person\": { \"id\": \"1\", \"firstname\":\"ryan\" } }" }
        it { should be_instance_of(Person) }
      end

      context "attributes that are defined" do
        let(:json) { "{\"person\": { \"id\": \"1\", \"firstname\":\"ryan\" } }" }
        it { should be_instance_of(Person) }
        it { should respond_to(:firstname) }
        its(:firstname) { should eq('ryan') }
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
        let(:json) { "[{ \"id\": 1, \"firstname\": \"ryan\" }]" }
        it { should raise_error }
      end

      context "there is no array of data" do
        let(:json) { "{ \"id\": 1, \"firstname\": \"ryan\" }" }
        it { should raise_error }
      end
    end

    context "when payload contains" do
      subject { serializer.extract_many(Person, json) }
      let(:collection) { subject }

      context "multiple records" do
        let(:json) do
          "{ \"people\": [{ \"id\": 1, \"firstname\": \"ryan\" }, { \"id\": 2, \"firstname\": \"ryan2\" }] }"
        end

        it { should have(2).items }

        it "should serialize one of the records" do
          expect(collection.first).to respond_to(:firstname)
          expect(collection.first.firstname).to eq('ryan')
        end
      end
    end

    context "using a different key name" do
      let(:json) do
        {
          peeps: [{
            id: 1,
            firstname: 'ryan'
          }]
        }.to_json
      end

      let(:collection) { serializer.extract_many(Person, json, "peeps") }

      subject { collection }
      it { should have(1).items }

      context "the person" do
        subject { collection.first }
        it { should be_instance_of(Person) }
        it { should respond_to(:firstname) }
        its(:firstname) { should eq('ryan') }
      end
    end
  end

  describe :extract_many_relationship do
    let(:person) { Person.new }

    it "should extact relationships using links" do
      expect(serializer).to receive(:extract_many_relationship_from_links)
        .with(person, :items, {}, "http://items.test")
        .and_return([])

      person.meta = {
        links: {
          'items' => "http://items.test"
        }
      }

      serializer.extract_many_relationship(
        person,
        :items,
        {},
        "{}"
      )
    end

    it "should extract relationships using sideloads" do
      items = "[{ \"id\": 1, \"name\": \"first\" }, { \"id\": 2, \"name\": \"second\" }]"
      response = "{ \"person\": { \"item_ids\": [1] }, \"items\": #{items} }"

      expect(serializer).to receive(:extract_many_relationship_from_sideload)
        .with(person, :items, {}, response)
        .and_return([])

      person.meta = {
        data: {
          'item_ids' => [1]
        }
      }

      serializer.extract_many_relationship(
        person,
        :items,
        {},
        response
      )
    end

    it "should not try to extract sideloads if the parent record doesnt have ids" do
      result = serializer.extract_many_relationship(
        person,
        :items,
        {},
        "{ \"person\": { }, \"items\": [{\"id\": 1 }] }"
      )

      expect(result).to match_array([])
    end

    it "should give an empty collection when there is no sideload or links present" do
      result = serializer.extract_many_relationship(
        person,
        :items,
        {},
        "{ \"person\": { } }"
      )

      expect(result).to match_array([])
    end
  end

  describe :extract_many_relationship_from_links do
    let(:person) { Person.new }
    let(:store) { double("store") }

    before(:each) do
      serializer.store = store

      expect(store).to receive(:load_collection)
        .with(Item, "http://www.example.com/items")
    end

    it "should have the store load the collection" do
      serializer.extract_many_relationship_from_links(
        person,
        :items,
        {},
        "http://www.example.com/items"
      )
    end

    it "should have the store load the collection for the given class" do
      serializer.extract_many_relationship_from_links(
        person,
        :oddly_named_items,
        { class_name: 'Item' },
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
        .with(Item, response, "items")
        .and_return([])

      serializer.extract_many_relationship_from_sideload(
        person,
        :items,
        {},
        response
      )
    end

    it "should pass the right class name to extract many" do
      expect(serializer).to receive(:extract_many)
        .with(CellPhone, response, "items")
        .and_return([])

      serializer.extract_many_relationship_from_sideload(
        person,
        :items,
        { class_name: 'CellPhone' },
        response
      )
    end

    it "should filter the ids in the relationship" do
      result = serializer.extract_many_relationship_from_sideload(
        person,
        :items,
        {},
        response
      )

      expect(result).to have(1).items
      expect(result.first.id).to eq(2)
    end
  end

  describe :extract_single_relationship do
    let(:person) { Person.new }
    let(:item) { Item.new }
    let(:response) { "{}" } # dummy response
    subject { serializer.extract_single_relationship(person, :item, {}, response) }

    context "from links" do
      let(:person) do
        Person.new(meta: { links: {
          'item' => 'http://example.com/item/1'
        }})
      end

      before(:each) do
        expect(serializer).to receive(:extract_single_relationship_from_links)
          .with(person, :item, {}, "http://example.com/item/1")
          .and_return(item)
      end

      it { should eq(item) }
    end

    context "from sideload" do
      let(:person) do
        Person.new(meta: { data: {
          'item_id' => 1
        }})
      end

      let(:response) do
        # for sideloader
        {
          items: [{
            id: 1,
          }]
        }.to_json
      end

      before(:each) do
        expect(serializer).to receive(:extract_single_relationship_from_sideload)
          .with(person, :item, {}, response)
          .and_return(item)
      end

      it { should eq(item) }
    end

    context "when nothing is found" do
      it { should be_nil }
    end
  end

  describe :extract_single_relationship_from_links do
    let(:store) { double("store") }
    let(:person) { Person.new }
    let(:item) { Item.new }

    before(:each) do
      serializer.store = store

      expect(store).to receive(:load_single)
        .with(Item, nil, "http://example.com/items/1")
        .and_return(item)
    end

    context "with no options" do
      subject do
        serializer.extract_single_relationship_from_links(
          person, :item, {}, "http://example.com/items/1"
        )
      end

      it { should eq(item) }
    end

    context "with a different class name" do
      subject do
        serializer.extract_single_relationship_from_links(
          person, :favorite_item, { class_name: 'Item' }, "http://example.com/items/1"
        )
      end

      it { should eq(item) }
    end
  end

  describe :extract_single_relationship_from_sideload do
    context "with no options" do
      let(:person) do
        Person.new(meta: { data: {
          'item_id' => 2
        }})
      end

      subject do
        serializer.extract_single_relationship_from_sideload(
          person, :item, {}, response
        )
      end

      let(:response) do
        {
          person: {
            id: 1,
            item_id: 2
          },
          items: [{
            id: 1,
            name: 'not for person'
          },{
            id: 2,
            name: 'persons item'
          }]
        }.to_json
      end

      it { should be_instance_of(Item) }
      its(:id) { should eq(2) }
      its(:name) { should eq('persons item') }
    end

    context "with a different class name" do
      let(:person) do
        Person.new(meta: { data: {
          'favorite_item_id' => 2
        }})
      end

      subject do
        serializer.extract_single_relationship_from_sideload(
          person, :favorite_item, { class_name: 'Item' }, response
        )
      end

      let(:response) do
        {
          person: {
            id: 1,
            favorite_item_id: 2
          },
          favorite_items: [{
            id: 1,
            name: 'not for person'
          },{
            id: 2,
            name: 'persons item'
          }]
        }.to_json
      end

      it { should be_instance_of(Item) }
      its(:id) { should eq(2) }
      its(:name) { should eq('persons item') }
    end
  end
end
