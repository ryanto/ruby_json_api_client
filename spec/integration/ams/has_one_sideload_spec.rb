require 'spec_helper'

describe "AMS load has_one sideloaded records" do

  before(:each) do
    RubyJsonApiClient::Store.register_adapter(:ams, {
      hostname: 'www.example.com'
    });

    RubyJsonApiClient::Store.register_serializer(:ams)

    RubyJsonApiClient::Store.default(:ams)
  end

  context "using standard sideloading" do
    before(:each) do
      response = {
        person: {
          id: 123,
          firstname: "ryan",
          item_id: 1
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
    let!(:item) { person.item }

    context "the person" do
      subject { person }
      its(:id) { should eq(123) }
      its(:firstname) { should eq('ryan') }
    end

    context "the item" do
      subject { item }
      its(:name) { should eq('first') }
      its(:id) { should eq(1) }
    end
  end

  context "using a different relationship class name" do
    before(:each) do
      response = {
        person: {
          id: 123,
          firstname: "ryan",
          item_id: 1,
          favorite_item_id: 2
        },
        favorite_items: [{
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
    let(:favorite_item) { person.favorite_item }

    subject { favorite_item }
    its(:name) { should eq('second') }
    its(:id) { should eq(2) }
  end
end
