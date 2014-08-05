require 'spec_helper'

describe "AMS load has_many linked records" do

  before(:each) do
    RubyJsonApiClient::Store.register_adapter(:ams, {
      hostname: 'www.example.com'
    });

    RubyJsonApiClient::Store.register_serializer(:ams)

    RubyJsonApiClient::Store.default(:ams)
  end

  context "that are loaded" do
    before(:each) do
      people_response = {
        people: [{
          id: 123,
          firstname: 'ryan',
          lastname: 'test',
          links: {
            items: "http://www.example.com/items?person=123"
          }
        },{
          id: 456,
          firstname: 'testing',
          lastname: 'again',
          links: {
            items: "/items?person=456"
          }
        }]
      }.to_json

      items_response = {
        items: [{
          id: 10,
          name: "testing"
        },{
          id: 11,
          name: "another test"
        }]
      }.to_json

      no_items_response = {
        items: []
      }.to_json

      stub_request(:get, "http://www.example.com/people")
        .to_return(
          status: 200,
          body: people_response,
        )

      stub_request(:get, "http://www.example.com/items?person=123")
        .to_return(
          status: 200,
          body: items_response
        )

      stub_request(:get, "http://www.example.com/items?person=456")
        .to_return(
          status: 200,
          body: no_items_response
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
          .to match_array(['testing', 'another test'])
      end

      context "and their first item" do
        subject { person1.items[0] }
        its(:id) { should eq(10) }
        its(:name) { should eq("testing") }
      end

      context "and their second item" do
        subject { person1.items[1] }
        its(:id) { should eq(11) }
        its(:name) { should eq("another test") }
      end
    end
  end

  context "that are not loaded" do
    # this tests Person.new(id: 123).items will load the person
    # then load the items

    before(:each) do
      person_response = {
        person: {
          id: 123,
          firstname: "ryan",
          links: {
            # use a strange url
            items: "/testing/items?p_id=123"
          }
        }
      }.to_json

      items_response = {
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
          body: person_response,
        )

      stub_request(:get, "http://www.example.com/testing/items?p_id=123")
        .to_return(
          status: 200,
          body: items_response,
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
end
