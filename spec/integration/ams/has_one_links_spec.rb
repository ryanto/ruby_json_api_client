require 'spec_helper'

describe "AMS load has_one linked record" do

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

    has_one :item

    def full_name
      "#{firstname} #{lastname}"
    end
  end

  class Item < RubyJsonApiClient::Base
    field :name
  end

  before(:each) do
    person_response = {
      person: {
        id: 123,
        firstname: 'ryan',
        lastname: 'test',
        links: {
          item: "http://www.example.com/items/10"
        }
      }
    }.to_json

    item_response = {
      item: {
        id: 10,
        name: "testing"
      }
    }.to_json

    stub_request(:get, "http://www.example.com/people/123")
      .to_return(
        status: 200,
        body: person_response,
      )

      stub_request(:get, "http://www.example.com/items/10")
        .to_return(
          status: 200,
          body: item_response
        )
  end


  let(:person) { Person.find(123) }
  let(:item) { person.item }

  context "the item" do
    subject { item }
    it { should be_instance_of(Item) }
    its(:id) { should eq(10) }
    its(:name) { should eq('testing') }
  end
end
