require 'spec_helper'

describe "AMS load has_many sideloaded records" do

  before(:each) do
    RubyJsonApiClient::Store.register_adapter(:ams, {
      hostname: 'www.example.com'
    });

    RubyJsonApiClient::Store.register_serializer(:ams)

    RubyJsonApiClient::Store.default(:ams)
  end

  class Person < RubyJsonApiClient::Base
    field :firstname
    field :lastname

    has_many :items
    has_many :other_items, class_name: 'Item'

    def full_name
      "#{firstname} #{lastname}"
    end
  end

  class Item < RubyJsonApiClient::Base
    field :name
  end

  context "that are loaded" do
    before(:each) do
      response = {
        people: [{
          id: 123,
          firstname: 'ryan',
          lastname: 'test',
          item_ids: [1,2]
        },{
          id: 456,
          firstname: 'testing',
          lastname: 'again',
          item_ids: [2,3]
        }],
        items: [{
          id: 1,
          name: 'test 1'
        },{
          id: 2,
          name: 'test 2'
        },{
          id: 3,
          name: 'test 3'
        },{
          id: 4,
          name: 'test 4'
        }]
      }.to_json

      stub_request(:get, "http://www.example.com/people")
        .to_return(
          status: 200,
          body: response,
        )
    end

    let(:collection) { Person.all }
    let(:person1) { collection[0] }
    let(:person2) { collection[1] }

    context "using the first person" do
      subject { person1 }
      its(:id) { should eq(123) }
      its(:items) { should have(2).items }

      it "should have mappable items" do
        expect(person1.items.map(&:name))
          .to match_array(['test 1', 'test 2'])
      end

      context "and their first item" do
        subject { person1.items[0] }
        its(:id) { should eq(1) }
        its(:name) { should eq("test 1") }
      end

      context "and their second item" do
        subject { person1.items[1] }
        its(:id) { should eq(2) }
        its(:name) { should eq("test 2") }
      end
    end
  end

  context "that are not loaded" do
    # this tests Person.new(id: 123).items will load the person
    # then load the items

    before(:each) do
      response = {
        person: {
          id: 123,
          firstname: "ryan",
          item_ids: [1, 2]
        },
        items: [{
          id: 1,
          name: "first"
        }, {
          id: 2,
          name: "second"
        }]
      }.to_json

      stub_request(:get, "http://www.example.com/people/123")
        .to_return(
          status: 200,
          body: response,
        )
    end

    let(:person) { Person.new(id: 123) }
    let(:items) { person.items }

    context "the person" do
      subject { person }

      before(:each) do
        # load items (which should load person)
        person.items
      end

      its(:id) { should eq(123) }
      its(:firstname) { should eq('ryan') }
    end

    context "the items" do
      subject { items }
      it { should have(2).items }

      context "the first item" do
        subject { items[0] }
        its(:name) { should eq('first') }
        its(:id) { should eq(1) }
      end
    end
  end

  context "using a different relationship class name" do
    before(:each) do
      response = {
        person: {
          id: 123,
          firstname: "ryan",
          other_item_ids: [1, 2]
        },
        other_items: [{
          id: 1,
          name: "first"
        },{
          id: 2,
          name: "second"
        }]
      }.to_json

      stub_request(:get, "http://www.example.com/people/123")
        .to_return(
          status: 200,
          body: response,
        )
    end

    let(:person) { Person.new(id: 123) }
    let(:other_items) { person.other_items }

    subject { other_items }
    it { should have(2).items }

    context "the first item" do
      subject { other_items[0] }
      its(:name) { should eq('first') }
      its(:id) { should eq(1) }
    end
  end

end
